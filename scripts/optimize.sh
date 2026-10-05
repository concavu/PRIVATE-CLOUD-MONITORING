#!/usr/bin/env bash
# ==============================================================================
# NEXTCLOUD SECURITY & DATABASE TUNING SCRIPT
# Run once after first initialization to fix all Nextcloud admin overview warnings.
# ==============================================================================

set -euo pipefail

echo "[+] Đang tối ưu hóa cơ sở dữ liệu và bảo mật Nextcloud..."

# 1. Bổ sung các chỉ mục Database thiếu
docker exec -u www-data nextcloud_app_core php occ db:add-missing-indices

# 2. Bổ sung các cột và khóa chính còn thiếu
docker exec -u www-data nextcloud_app_core php occ db:add-missing-columns
docker exec -u www-data nextcloud_app_core php occ db:add-missing-primary-keys

# 3. Cấu hình vùng điện thoại mặc định (Việt Nam)
docker exec -u www-data nextcloud_app_core php occ config:system:set default_phone_region --value="VN"

# 4. Cấu hình thời gian bảo trì hệ thống (01:00 AM UTC)
docker exec -u www-data nextcloud_app_core php occ config:system:set maintenance_window_start --type=integer --value=1

# 5. Kích hoạt Memory Caching & Locking qua Redis
docker exec -u www-data nextcloud_app_core php occ config:system:set memcache.local --value="\OC\Memcache\Redis"
docker exec -u www-data nextcloud_app_core php occ config:system:set memcache.distributed --value="\OC\Memcache\Redis"
docker exec -u www-data nextcloud_app_core php occ config:system:set memcache.locking --value="\OC\Memcache\Redis"

echo "[✔] Hoàn tất tối ưu hóa Nextcloud! Kiểm tra tại giao diện Admin Overview."
