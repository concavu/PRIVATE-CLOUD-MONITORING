#!/usr/bin/env bash
# ==============================================================================
# ENTERPRISE DISASTER RECOVERY & BACKUP SCRIPT
# Project: Containerized Private Cloud Storage
# Functions: Database Dump, Config Archive, S3 Bucket Snapshot, GPG Encryption,
#            Automated 7-Day Retention Cleanup.
# ==============================================================================

set -euo pipefail

# Định nghĩa đường dẫn
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${BASE_DIR}/backups"
LOG_FILE="${BACKUP_DIR}/backup.log"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
TMP_DIR="${BACKUP_DIR}/tmp_${TIMESTAMP}"

# Load Environment Variables từ .env
if [ -f "${BASE_DIR}/.env" ]; then
    # shellcheck disable=SC1091
    source "${BASE_DIR}/.env"
else
    echo "[ERROR] Không tìm thấy file .env tại ${BASE_DIR}" | tee -a "${LOG_FILE}"
    exit 1
fi

mkdir -p "${BACKUP_DIR}" "${TMP_DIR}"

log() {
    local level="$1"
    shift
    local msg="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${msg}" | tee -a "${LOG_FILE}"
}

log "INFO" "==================== KHỞI CHẠY BACKUP HẠ TẦNG ===================="
log "INFO" "Thời gian: ${TIMESTAMP} | Thư mục lưu: ${BACKUP_DIR}"

# 1. Bật chế độ bảo trì Nextcloud (Maintenance Mode) để đảm bảo tính toàn vẹn dữ liệu
log "INFO" "[1/6] Đưa Nextcloud vào trạng thái Maintenance Mode..."
docker exec -u www-data nextcloud_app_core php occ maintenance:mode --on 2>/dev/null || {
    log "WARN" "Nextcloud chưa sẵn sàng hoặc không thể bật maintenance mode. Vẫn tiếp tục backup..."
}

# 2. Dump Database MariaDB với cờ --single-transaction để không lock bảng
log "INFO" "[2/6] Đang xuất (dump) cơ sở dữ liệu MariaDB [${MYSQL_DATABASE}]..."
DB_DUMP_FILE="${TMP_DIR}/mariadb_${MYSQL_DATABASE}_${TIMESTAMP}.sql"
docker exec mariadb_db_engine sh -c \
    'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mariadb-dump -u root --single-transaction --quick --routines --triggers "$MYSQL_DATABASE"' \
    > "${DB_DUMP_FILE}"

log "INFO" "Dump Database hoàn tất: $(du -sh "${DB_DUMP_FILE}" | awk '{print $1}')"

# 3. Sao lưu cấu hình Nextcloud (config.php và các app đã cài)
log "INFO" "[3/6] Sao lưu tệp cấu hình Nextcloud config/..."
CONFIG_TAR_FILE="${TMP_DIR}/nextcloud_config_${TIMESTAMP}.tar.gz"
docker exec nextcloud_app_core tar -czf - /var/www/html/config > "${CONFIG_TAR_FILE}"

# 4. Sao lưu dữ liệu MinIO S3 Bucket (Metadata + Objects)
log "INFO" "[4/6] Sao lưu dữ liệu Object Storage từ MinIO..."
MINIO_DATA_TAR="${TMP_DIR}/minio_data_${TIMESTAMP}.tar.gz"
docker run --rm \
    --network net_cloud_storage \
    -v minio_data:/data:ro \
    alpine tar -czf - /data > "${MINIO_DATA_TAR}"

# 5. Tắt chế độ bảo trì Nextcloud ngay sau khi snapshot xong
log "INFO" "[5/6] Tắt Maintenance Mode cho Nextcloud..."
docker exec -u www-data nextcloud_app_core php occ maintenance:mode --off 2>/dev/null || true

# 6. Đóng gói toàn bộ và Mã hóa GPG
ARCHIVE_NAME="cloud_backup_${TIMESTAMP}.tar.gz"
FINAL_ARCHIVE="${TMP_DIR}/${ARCHIVE_NAME}"
ENCRYPTED_FILE="${BACKUP_DIR}/${ARCHIVE_NAME}.gpg"

log "INFO" "[6/6] Đóng gói và mã hóa GPG (AES-256 / Asymmetric)..."
tar -czf "${FINAL_ARCHIVE}" -C "${TMP_DIR}" \
    "$(basename "${DB_DUMP_FILE}")" \
    "$(basename "${CONFIG_TAR_FILE}")" \
    "$(basename "${MINIO_DATA_TAR}")"

# Kiểm tra nếu có GPG Public Key định danh (Recipient), nếu không thì mã hóa Symmetric chuẩn AES256
GPG_RECIPIENT="${GPG_RECIPIENT:-}"
if [ -n "${GPG_RECIPIENT}" ]; then
    log "INFO" "Mã hóa bằng GPG Asymmetric Public Key cho [${GPG_RECIPIENT}]..."
    gpg --batch --yes --encrypt --recipient "${GPG_RECIPIENT}" --output "${ENCRYPTED_FILE}" "${FINAL_ARCHIVE}"
else
    log "INFO" "Mã hóa bằng GPG Symmetric (AES-256) sử dụng Security Key..."
    BACKUP_PASSPHRASE="${MYSQL_ROOT_PASSWORD}"
    echo "${BACKUP_PASSPHRASE}" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 --output "${ENCRYPTED_FILE}" "${FINAL_ARCHIVE}"
fi

# Dọn dẹp thư mục tạm
rm -rf "${TMP_DIR}"

log "INFO" "Bản backup đã được mã hóa thành công: ${ENCRYPTED_FILE}"
log "INFO" "Kích thước: $(du -sh "${ENCRYPTED_FILE}" | awk '{print $1}')"

# 7. Chính sách dọn dẹp (Retention Policy): Xóa các bản backup cũ hơn 7 ngày
log "INFO" "Kiểm tra và dọn dẹp các bản backup cũ hơn 7 ngày..."
DELETED_COUNT=0
while IFS= read -r old_file; do
    if [ -n "${old_file}" ]; then
        rm -f "${old_file}"
        log "INFO" "Đã xóa bản backup cũ: ${old_file}"
        DELETED_COUNT=$((DELETED_COUNT + 1))
    fi
done < <(find "${BACKUP_DIR}" -type f -name "cloud_backup_*.tar.gz.gpg" -mtime +7)

log "INFO" "Tổng số file cũ đã dọn dẹp: ${DELETED_COUNT}"
log "INFO" "==================== HOÀN TẤT BACKUP THÀNH CÔNG ===================="
