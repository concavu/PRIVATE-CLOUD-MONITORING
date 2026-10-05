# ==============================================================================
# POWERSHELL BACKUP HELPER FOR WINDOWS
# ==============================================================================
$ErrorActionPreference = "Stop"

$BaseDir = Split-Path -Parent $PSScriptRoot
$BackupDir = Join-Path $BaseDir "backups"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$TmpDir = Join-Path $BackupDir "tmp_$Timestamp"

Write-Host "[+] Khoi tao thu muc backup..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null

# 1. Bật maintenance mode
Write-Host "[1/4] Bat Nextcloud maintenance mode..." -ForegroundColor Yellow
docker exec -u www-data nextcloud_app_core php occ maintenance:mode --on 2>$null

# 2. Dump DB
Write-Host "[2/4] Xuat MariaDB database..." -ForegroundColor Yellow
$DbFile = Join-Path $TmpDir "mariadb_dump_$Timestamp.sql"
docker exec mariadb_db_engine sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mariadb-dump -u root --single-transaction --quick "$MYSQL_DATABASE"' | Out-File -FilePath $DbFile -Encoding utf8
if ($LASTEXITCODE -ne 0) {
    throw "MariaDB dump failed (docker exit code $LASTEXITCODE)."
}

# 3. Tat maintenance mode
Write-Host "[3/4] Tat maintenance mode..." -ForegroundColor Yellow
docker exec -u www-data nextcloud_app_core php occ maintenance:mode --off 2>$null

# 4. Nen file zip
Write-Host "[4/4] Nen file sao luu..." -ForegroundColor Yellow
$ZipFile = Join-Path $BackupDir "cloud_backup_$Timestamp.zip"
Compress-Archive -Path "$TmpDir\*" -DestinationPath $ZipFile -Force
Remove-Item -Recurse -Force $TmpDir

Write-Host "[OK] Sao luu thanh cong tai: $ZipFile" -ForegroundColor Green
