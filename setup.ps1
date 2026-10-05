# ==============================================================================
# POWERSHELL SETUP & VERIFY FOR WINDOWS
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host "[+] Kiem tra cau truc thu muc..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "nginx\ssl", "nginx\conf.d", "scripts", "backups" | Out-Null

if (-not (Test-Path ".env")) {
    Write-Host "[!] Dang tao file .env tu .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
}

if (-not (Test-Path "nginx\ssl\server.crt")) {
    Write-Host "[!] Khong tim thay SSL cert. Vui long sinh khoa hoac dung file co san." -ForegroundColor Red
} else {
    Write-Host "[✔] Chung chi SSL da san sang tai nginx/ssl!" -ForegroundColor Green
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Ha tang da san sang! Chay lenh sau de khoi dong:" -ForegroundColor Green
Write-Host "    docker compose up -d" -ForegroundColor Yellow
Write-Host "Kiem tra tien trinh:" -ForegroundColor Cyan
Write-Host "    docker compose ps" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan
