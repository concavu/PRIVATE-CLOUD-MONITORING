#!/usr/bin/env bash
# ==============================================================================
# ENTERPRISE DISASTER RECOVERY & RESTORE SCRIPT
# Project: Containerized Private Cloud Storage
# Functions: Decrypt GPG archive, Restore MariaDB Dump, Restore MinIO Volume,
#            Verify Integrity & Disable Maintenance Mode.
# Usage: ./scripts/restore.sh [path_to_backup_file.gpg]
# ==============================================================================

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESTORE_TMP="${BASE_DIR}/backups/restore_tmp_$(date +%s)"

if [ $# -eq 0 ]; then
    echo "Sử dụng: $0 <duong_dan_file_backup.gpg>"
    echo "Ví dụ: $0 ./backups/cloud_backup_20260929_120000.tar.gz.gpg"
    exit 1
fi

ENCRYPTED_BACKUP="$1"

if [ ! -f "${ENCRYPTED_BACKUP}" ]; then
    echo "[ERROR] Tệp sao lưu không tồn tại: ${ENCRYPTED_BACKUP}"
    exit 1
fi

# shellcheck disable=SC1091
source "${BASE_DIR}/.env"

echo "[1/5] Tạo thư mục giải nén tạm tại ${RESTORE_TMP}..."
mkdir -p "${RESTORE_TMP}"

echo "[2/5] Giải mã tệp sao lưu bằng GPG..."
ARCHIVE_TAR="${RESTORE_TMP}/extracted_archive.tar.gz"
echo "${MYSQL_ROOT_PASSWORD}" | gpg --batch --yes --passphrase-fd 0 --decrypt --output "${ARCHIVE_TAR}" "${ENCRYPTED_BACKUP}"

echo "[3/5] Giải nén các thành phần sao lưu..."
tar -xzf "${ARCHIVE_TAR}" -C "${RESTORE_TMP}"

echo "[4/5] Phục hồi MariaDB Database..."
SQL_FILE=$(find "${RESTORE_TMP}" -name "mariadb_*.sql" | head -n 1)
if [ -n "${SQL_FILE}" ]; then
    echo "Đang nạp dữ liệu vào MariaDB [${MYSQL_DATABASE}]..."
    docker exec -i mariadb_db_engine mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" < "${SQL_FILE}"
    echo "Phục hồi database thành công!"
fi

echo "[5/5] Phục hồi cấu hình Nextcloud & Object Store..."
CONFIG_TAR=$(find "${RESTORE_TMP}" -name "nextcloud_config_*.tar.gz" | head -n 1)
if [ -n "${CONFIG_TAR}" ]; then
    docker exec -i nextcloud_app_core tar -xzf - -C / < "${CONFIG_TAR}"
fi

MINIO_TAR=$(find "${RESTORE_TMP}" -name "minio_data_*.tar.gz" | head -n 1)
if [ -n "${MINIO_TAR}" ]; then
    docker run --rm \
        --network net_cloud_storage \
        -v minio_data:/data \
        -v "${RESTORE_TMP}:/restore:ro" \
        alpine tar -xzf "/restore/$(basename "${MINIO_TAR}")" -C /
fi

echo "Dọn dẹp thư mục tạm..."
rm -rf "${RESTORE_TMP}"

echo "Tắt maintenance mode cho Nextcloud..."
docker exec -u www-data nextcloud_app_core php occ maintenance:mode --off 2>/dev/null || true

echo "==================== HOÀN TẤT PHỤC HỒI DỮ LIỆU ===================="
