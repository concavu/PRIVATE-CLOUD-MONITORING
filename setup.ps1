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

$EnvPath = Join-Path (Get-Location) ".env"
$EnvLines = [System.Collections.Generic.List[string]]::new()
$EnvLines.AddRange([string[]](Get-Content -LiteralPath $EnvPath))
$SecretKeys = @("ADMIN_PASSWORD", "MYSQL_ROOT_PASSWORD", "MYSQL_PASSWORD", "MYSQL_EXPORTER_PASSWORD", "REDIS_PASSWORD", "MINIO_ROOT_PASSWORD", "GRAFANA_ADMIN_PASSWORD")
$EnvChanged = $false
foreach ($SecretKey in $SecretKeys) {
    $LineIndex = -1
    for ($Index = 0; $Index -lt $EnvLines.Count; $Index++) {
        if ($EnvLines[$Index] -match "^$SecretKey=") {
            $LineIndex = $Index
            break
        }
    }

    $NeedsSecret = $LineIndex -lt 0
    if (-not $NeedsSecret) {
        $SecretValue = $EnvLines[$LineIndex] -replace "^$SecretKey=", ''
        $NeedsSecret = [string]::IsNullOrWhiteSpace($SecretValue) -or $SecretValue -match '^(?i:replace-with-a-long-random-password|REPLACE_.*)$'
    }

    if ($NeedsSecret) {
        $RandomBytes = New-Object byte[] 32
        $RandomGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try {
            $RandomGenerator.GetBytes($RandomBytes)
        } finally {
            $RandomGenerator.Dispose()
        }
        $Secret = [System.BitConverter]::ToString($RandomBytes).Replace("-", "").ToLowerInvariant()
        $SecretLine = "$SecretKey=$Secret"
        if ($LineIndex -lt 0) {
            $EnvLines.Add($SecretLine)
        } else {
            $EnvLines[$LineIndex] = $SecretLine
        }
        $EnvChanged = $true
        Write-Host "[OK] Da tao gia tri ngau nhien cho $SecretKey." -ForegroundColor Green
    }
}

if ($EnvChanged) {
    $Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($EnvPath, $EnvLines, $Utf8WithoutBom)
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
