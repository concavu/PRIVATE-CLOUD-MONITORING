#!/usr/bin/env bash
# ==============================================================================
# AUTOMATED SETUP & BOOTSTRAP SCRIPT
# Project: Containerized Private Cloud Storage (Enterprise Grade)
# ==============================================================================

set -euo pipefail

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

# 2. Sinh cặp chứng chỉ SSL/TLS Self-Signed cho Nginx Reverse Proxy
SSL_DIR="./nginx/ssl"
if [ ! -f "$SSL_DIR/server.crt" ] || [ ! -f "$SSL_DIR/server.key" ]; then
    echo -e "${BLUE}[+] Đang sinh cặp chứng chỉ SSL/TLS (Self-Signed 2048-bit RSA)...${NC}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
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
