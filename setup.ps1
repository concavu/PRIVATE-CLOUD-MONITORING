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

if (-not (Test-Path "nginx\ssl\server.crt") -or -not (Test-Path "nginx\ssl\server.key")) {
    $OpenSsl = Get-Command openssl -ErrorAction SilentlyContinue
    if (-not $OpenSsl) {
        throw "OpenSSL is required to generate the local TLS certificate. Install OpenSSL or place server.crt and server.key in nginx\ssl."
    }

    Write-Host "[+] Dang tao chung chi TLS self-signed..." -ForegroundColor Cyan
    & $OpenSsl.Source req -x509 -nodes -days 365 -newkey rsa:2048 `
        -keyout "nginx\ssl\server.key" `
        -out "nginx\ssl\server.crt" `
        -subj "/C=VN/ST=Hanoi/L=Hanoi/O=PrivateCloud/OU=DevOps/CN=cloud.local" `
        -addext "subjectAltName=DNS:cloud.local,DNS:localhost,IP:127.0.0.1"
    if ($LASTEXITCODE -ne 0) {
        throw "OpenSSL failed to generate the local TLS certificate."
    }
}
Write-Host "[OK] Chung chi SSL da san sang tai nginx/ssl!" -ForegroundColor Green

Write-Host '======================================================================' -ForegroundColor Cyan
Write-Host 'Ha tang da san sang! Chay lenh sau de khoi dong:' -ForegroundColor Green
Write-Host '    docker compose up -d' -ForegroundColor Yellow
Write-Host 'Kiem tra tien trinh:' -ForegroundColor Cyan
Write-Host '    docker compose ps' -ForegroundColor Yellow
Write-Host '======================================================================' -ForegroundColor Cyan
