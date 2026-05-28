$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path (Get-Location) "backups"
$backupFile = Join-Path $backupDir "tcg-platform-$timestamp.sql"

New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Write-Host "Creating database backup: $backupFile" -ForegroundColor Cyan
docker compose exec -T db mysqldump -uroot -proot wordpress | Set-Content -Path $backupFile -Encoding UTF8
Write-Host "Backup created." -ForegroundColor Green
