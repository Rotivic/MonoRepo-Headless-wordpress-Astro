$ErrorActionPreference = "Stop"

function Step($Name, $Command) {
  Write-Host ""
  Write-Host "==> $Name" -ForegroundColor Cyan
  Invoke-Expression $Command
}

Step "Docker Compose services" "docker compose ps"
Step "WordPress health" "Invoke-WebRequest -UseBasicParsing http://localhost:8080/wp-json/tcg/v1/health | Select-Object StatusCode,RawContentLength"
Step "Astro health" "Invoke-WebRequest -UseBasicParsing http://localhost:4321 | Select-Object StatusCode,RawContentLength"
Step "Mailpit health" "Invoke-WebRequest -UseBasicParsing http://localhost:8025 | Select-Object StatusCode,RawContentLength"
Step "Redis status" "docker compose exec php wp redis status --allow-root"
Step "WordPress plugins" "docker compose exec php wp plugin list --fields=name,status,version --allow-root"
Step "Astro build" "docker compose exec web npm run build"

Write-Host ""
Write-Host "Doctor completed." -ForegroundColor Green
