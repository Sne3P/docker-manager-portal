# Container Manager Platform - Complete Docker Cleanup Script
Write-Host "🧹 NETTOYAGE COMPLET DOCKER - Container Manager Platform" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Change to project directory
$projectPath = "c:\Users\basti\Documents\Workspace\Cloud Project\portail-cloud-container"
Set-Location $projectPath

Write-Host "1. Arrêt de tous les services..." -ForegroundColor Yellow
docker-compose down --remove-orphans 2>$null

Write-Host "2. Suppression des containers arrêtés..." -ForegroundColor Yellow
docker container prune -f

Write-Host "3. Suppression des images inutilisées..." -ForegroundColor Yellow
docker image prune -a -f

Write-Host "4. Suppression des volumes non utilisés..." -ForegroundColor Yellow
docker volume prune -f

Write-Host "5. Suppression des réseaux non utilisés..." -ForegroundColor Yellow
docker network prune -f

Write-Host "6. Suppression du cache de build..." -ForegroundColor Yellow
docker builder prune -a -f

Write-Host ""
Write-Host "✅ Nettoyage Docker terminé!" -ForegroundColor Green
Write-Host ""

# Show disk space recovered
Write-Host "📊 Espace disque libéré:" -ForegroundColor Blue
docker system df

Write-Host ""
Write-Host "🔍 Containers restants:" -ForegroundColor Blue
docker ps -a

Write-Host ""
Write-Host "🖼️ Images restantes:" -ForegroundColor Blue
docker images