# Container Manager Platform - Docker Deployment Script
Write-Host "Container Manager Platform - Docker Deployment" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Change to project directory
$projectPath = "c:\Users\basti\Documents\Workspace\Cloud Project\portail-cloud-container"
Set-Location $projectPath

# Verify Docker is running
Write-Host "Checking Docker status..." -ForegroundColor Yellow
try {
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running"
    }
    Write-Host "Docker is running" -ForegroundColor Green
} catch {
    Write-Host "Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Stop existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose down --remove-orphans 2>$null

# Build and start services
Write-Host "Building and starting Docker services..." -ForegroundColor Yellow
Write-Host "This may take several minutes for the first build..." -ForegroundColor Gray

try {
    docker-compose up -d --build
    if ($LASTEXITCODE -ne 0) {
        throw "Docker deployment failed"
    }
    Write-Host "Docker services started successfully!" -ForegroundColor Green
} catch {
    Write-Host "Deployment failed" -ForegroundColor Red
    docker-compose logs --tail=10
    exit 1
}

# Wait for services
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Test backend
$maxAttempts = 20
$attempt = 0
do {
    $attempt++
    Write-Host "Testing backend health ($attempt/$maxAttempts)..." -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "Backend is ready!" -ForegroundColor Green
            break
        }
    } catch {
        if ($attempt -eq $maxAttempts) {
            Write-Host "Backend failed to start after $maxAttempts attempts" -ForegroundColor Red
            Write-Host "Backend logs:" -ForegroundColor Yellow
            docker-compose logs backend --tail=20
            exit 1
        }
        Start-Sleep -Seconds 3
    }
} while ($attempt -lt $maxAttempts)

# Test frontend
$attempt = 0
do {
    $attempt++
    Write-Host "Testing frontend health ($attempt/$maxAttempts)..." -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "Frontend is ready!" -ForegroundColor Green
            break
        }
    } catch {
        if ($attempt -eq $maxAttempts) {
            Write-Host "Frontend failed to start after $maxAttempts attempts" -ForegroundColor Red
            Write-Host "Frontend logs:" -ForegroundColor Yellow
            docker-compose logs frontend --tail=20
            exit 1
        }
        Start-Sleep -Seconds 3
    }
} while ($attempt -lt $maxAttempts)

# Show deployment status
Write-Host ""
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Show running containers
Write-Host "Running containers:" -ForegroundColor Blue
docker-compose ps

Write-Host ""
Write-Host "Application URLs:" -ForegroundColor Blue
Write-Host "  Dashboard:    http://localhost:3000" -ForegroundColor Cyan
Write-Host "  Backend API:  http://localhost:5000" -ForegroundColor Cyan
Write-Host "  Demo API:     http://localhost:3001" -ForegroundColor Cyan
Write-Host "  Demo Web:     http://localhost:8080" -ForegroundColor Cyan

Write-Host ""
Write-Host "Management commands:" -ForegroundColor Blue
Write-Host "  View logs:     docker-compose logs -f [service]" -ForegroundColor Gray
Write-Host "  Stop all:      docker-compose down" -ForegroundColor Gray
Write-Host "  Restart:       docker-compose restart [service]" -ForegroundColor Gray

Write-Host ""
Write-Host "Container Manager Platform is now running in Docker!" -ForegroundColor Green
Write-Host "You can now manage client containers from the dashboard." -ForegroundColor Yellow

# Open browser
Write-Host ""
Write-Host "Opening dashboard in browser..." -ForegroundColor Blue
Start-Process "http://localhost:3000"