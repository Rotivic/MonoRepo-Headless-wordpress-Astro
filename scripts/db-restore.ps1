param(
  [Parameter(Mandatory = $true)]
  [string] $Path
)

$ErrorActionPreference = "Stop"

$resolved = Resolve-Path -LiteralPath $Path

Write-Host "Restoring database from: $resolved" -ForegroundColor Yellow
Write-Host "This will overwrite data in the local wordpress database." -ForegroundColor Yellow

$confirmation = Read-Host "Type RESTORE to continue"
if ($confirmation -ne "RESTORE") {
  Write-Host "Restore cancelled."
  exit 1
}

Get-Content -LiteralPath $resolved -Raw | docker compose exec -T db mysql -uroot -proot wordpress
Write-Host "Restore completed." -ForegroundColor Green
