# ==============================================================================
# POWERSHELL NEXTCLOUD OPTIMIZER FOR WINDOWS
# ==============================================================================
Write-Host "[+] Toi uu hoa MariaDB indexes & Nextcloud Cache..." -ForegroundColor Cyan

docker exec -u www-data nextcloud_app_core php occ db:add-missing-indices
docker exec -u www-data nextcloud_app_core php occ db:add-missing-columns
docker exec -u www-data nextcloud_app_core php occ db:add-missing-primary-keys
docker exec -u www-data nextcloud_app_core php occ config:system:set default_phone_region --value="VN"
docker exec -u www-data nextcloud_app_core php occ config:system:set maintenance_window_start --type=integer --value=1
docker exec -u www-data nextcloud_app_core php occ config:system:set memcache.local --value="\OC\Memcache\Redis"
docker exec -u www-data nextcloud_app_core php occ config:system:set memcache.distributed --value="\OC\Memcache\Redis"
docker exec -u www-data nextcloud_app_core php occ config:system:set memcache.locking --value="\OC\Memcache\Redis"

Write-Host "[✔] Hoan tat toi uu hoa Nextcloud!" -ForegroundColor Green
