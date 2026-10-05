#!/usr/bin/env bash
# ==============================================================================
# AUTOMATED SETUP & BOOTSTRAP SCRIPT
# Project: Containerized Private Cloud Storage (Enterprise Grade)
# ==============================================================================

set -euo pipefail
umask 077

# Colors for logging
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[+] Khởi tạo cấu trúc thư mục dự án...${NC}"
mkdir -p nginx/ssl nginx/conf.d scripts backups

# 1. Tạo file .env từ .env.example nếu chưa tồn tại
if [ ! -f .env ]; then
    echo -e "${YELLOW}[!] Chưa tìm thấy file .env, sao chép từ .env.example...${NC}"
    cp .env.example .env
fi
chmod 600 .env

set_secret_if_missing_or_placeholder() {
    local key="$1"
    if ! grep -Eq "^${key}=[^[:space:]]+$" .env \
        || grep -Eiq "^${key}=(REPLACE_.*|replace-with-a-long-random-password)$" .env; then
        local secret
        secret="$(openssl rand -hex 32)"
        local env_tmp
        env_tmp="$(mktemp)"
        awk -v key="$key" -v secret="$secret" '
            BEGIN { found = 0 }
            index($0, key "=") == 1 {
                print key "=" secret
                found = 1
                next
            }
            { print }
            END {
                if (!found) print key "=" secret
            }
        ' .env > "$env_tmp"
        cat "$env_tmp" > .env
        rm -f "$env_tmp"
        echo -e "${GREEN}[✔] Đã tạo giá trị ngẫu nhiên cho ${key}.${NC}"
    fi
}

for secret_key in ADMIN_PASSWORD MYSQL_ROOT_PASSWORD MYSQL_PASSWORD MYSQL_EXPORTER_PASSWORD REDIS_PASSWORD MINIO_ROOT_PASSWORD GRAFANA_ADMIN_PASSWORD; do
    set_secret_if_missing_or_placeholder "$secret_key"
done

if [ -f .env ]; then
    chmod 600 .env
fi

# 2. Sinh cặp chứng chỉ SSL/TLS Self-Signed cho Nginx Reverse Proxy
SSL_DIR="./nginx/ssl"
if [ ! -f "$SSL_DIR/server.crt" ] || [ ! -f "$SSL_DIR/server.key" ]; then
    echo -e "${BLUE}[+] Đang sinh cặp chứng chỉ SSL/TLS (Self-Signed 2048-bit RSA)...${NC}"
    MSYS_NO_PATHCONV=1 openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/server.key" \
        -out "$SSL_DIR/server.crt" \
        -subj "/C=VN/ST=Hanoi/L=Hanoi/O=PrivateCloud/OU=DevOps/CN=cloud.local" \
        -addext "subjectAltName=DNS:cloud.local,DNS:localhost,IP:127.0.0.1"
    
    chmod 600 "$SSL_DIR/server.key"
    chmod 644 "$SSL_DIR/server.crt"
    echo -e "${GREEN}[✔] Cặp khóa SSL đã sẵn sàng tại $SSL_DIR!${NC}"
else
    echo -e "${GREEN}[✔] Cặp khóa SSL đã tồn tại. Bỏ qua bước sinh khóa.${NC}"
fi

# 3. Phân quyền thư mục
chmod +x scripts/*.sh 2>/dev/null || true

echo -e "${BLUE}======================================================================${NC}"
echo -e "${GREEN}Hạ tầng đã sẵn sàng! Chạy lệnh sau để khởi động toàn bộ Microservices:${NC}"
echo -e "    ${YELLOW}docker compose up -d${NC}"
echo -e "${BLUE}Kiểm tra trạng thái containers:${NC}"
echo -e "    ${YELLOW}docker compose ps${NC}"
echo -e "${BLUE}Xem log quá trình khởi tạo Nextcloud & MinIO:${NC}"
echo -e "    ${YELLOW}docker compose logs -f nextcloud${NC}"
echo -e "${BLUE}======================================================================${NC}"
