# Container Manager Platform - Docker Management Script

param(
    [Parameter(Position=0)]
    [ValidateSet("stop", "restart", "status", "logs", "clean", "scale")]
    [string]$Action = "status",
    
    [Parameter(Position=1)]
    [string]$Service = "",
    
    [Parameter()]
    [int]$Replicas = 1
)

Write-Host "🐳 Container Manager Platform - Docker Management" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Change to project directory
$projectPath = "c:\Users\basti\Documents\Workspace\Cloud Project\portail-cloud-container"
Set-Location $projectPath

switch ($Action) {
    "stop" {
        Write-Host "🛑 Stopping Docker services..." -ForegroundColor Yellow
        if ($Service) {
            docker-compose stop $Service
            Write-Host "✅ Service '$Service' stopped" -ForegroundColor Green
        } else {
            docker-compose down
            Write-Host "✅ All services stopped" -ForegroundColor Green
        }
    }
    
    "restart" {
        Write-Host "🔄 Restarting Docker services..." -ForegroundColor Yellow
        if ($Service) {
            docker-compose restart $Service
            Write-Host "✅ Service '$Service' restarted" -ForegroundColor Green
        } else {
            docker-compose restart
            Write-Host "✅ All services restarted" -ForegroundColor Green
        }
    }
    
    "status" {
        Write-Host "📊 Docker Services Status:" -ForegroundColor Blue
        Write-Host ""
        
        # Show container status
        docker-compose ps
        
        Write-Host ""
        Write-Host "🔍 Detailed container information:" -ForegroundColor Blue
        
        # Get container stats
        $containers = docker-compose ps --services
        foreach ($container in $containers) {
            if ($container.Trim()) {
                Write-Host ""
                Write-Host "📦 $container:" -ForegroundColor Yellow
                $containerName = "container-manager-$container"
                if ($container -eq "backend") { $containerName = "container-manager-backend" }
                elseif ($container -eq "frontend") { $containerName = "container-manager-frontend" }
                elseif ($container -eq "redis") { $containerName = "container-manager-redis" }
                elseif ($container -eq "nginx") { $containerName = "container-manager-nginx" }
                
                try {
                    $inspect = docker inspect $containerName 2>$null | ConvertFrom-Json
                    if ($inspect) {
                        $state = $inspect.State
                        $created = [DateTime]::Parse($inspect.Created).ToString("yyyy-MM-dd HH:mm:ss")
                        $ports = ($inspect.NetworkSettings.Ports.PSObject.Properties | ForEach-Object { 
                            if ($_.Value) { "$($_.Name) -> $($_.Value[0].HostPort)" }
                        }) -join ", "
                        
                        Write-Host "   Status: $($state.Status)" -ForegroundColor $(if($state.Status -eq "running"){"Green"}else{"Red"})
                        Write-Host "   Created: $created" -ForegroundColor Gray
                        Write-Host "   Ports: $ports" -ForegroundColor Gray
                        
                        if ($state.Status -eq "running") {
                            $started = [DateTime]::Parse($state.StartedAt).ToString("yyyy-MM-dd HH:mm:ss")
                            Write-Host "   Started: $started" -ForegroundColor Gray
                        }
                    }
                } catch {
                    Write-Host "   Status: Not found or stopped" -ForegroundColor Red
                }
            }
        }
        
        Write-Host ""
        Write-Host "🌐 Available URLs:" -ForegroundColor Blue
        Write-Host "   Dashboard: http://localhost:3000" -ForegroundColor Cyan
        Write-Host "   API:       http://localhost:5000" -ForegroundColor Cyan
        Write-Host "   Demo API:  http://localhost:3001" -ForegroundColor Cyan
        Write-Host "   Demo Web:  http://localhost:8080" -ForegroundColor Cyan
    }
    
    "logs" {
        if ($Service) {
            Write-Host "📋 Showing logs for service: $Service" -ForegroundColor Blue
            docker-compose logs -f --tail=50 $Service
        } else {
            Write-Host "📋 Showing logs for all services (Press Ctrl+C to exit):" -ForegroundColor Blue
            docker-compose logs -f --tail=20
        }
    }
    
    "clean" {
        Write-Host "🧹 Cleaning Docker resources..." -ForegroundColor Yellow
        
        $confirm = Read-Host "This will remove stopped containers, unused networks, and dangling images. Continue? (y/N)"
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            # Stop services first
            docker-compose down --remove-orphans
            
            # Clean up Docker resources
            docker system prune -f
            docker volume prune -f
            
            Write-Host "✅ Docker resources cleaned" -ForegroundColor Green
        } else {
            Write-Host "❌ Clean operation cancelled" -ForegroundColor Red
        }
    }
    
    "scale" {
        if (-not $Service) {
            Write-Host "❌ Service name is required for scaling" -ForegroundColor Red
            Write-Host "Usage: .\manage-docker.ps1 scale <service-name> -Replicas <number>" -ForegroundColor Yellow
            Write-Host "Available services: backend, frontend, demo-api, demo-web, demo-worker" -ForegroundColor Gray
            return
        }
        
        Write-Host "📈 Scaling service '$Service' to $Replicas replicas..." -ForegroundColor Yellow
        docker-compose up -d --scale $Service=$Replicas
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Service '$Service' scaled to $Replicas replicas" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to scale service '$Service'" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "💡 Available commands:" -ForegroundColor Blue
Write-Host "   .\manage-docker.ps1 status                    # Show status of all services" -ForegroundColor Gray
Write-Host "   .\manage-docker.ps1 stop [service]            # Stop all services or specific service" -ForegroundColor Gray
Write-Host "   .\manage-docker.ps1 restart [service]         # Restart all services or specific service" -ForegroundColor Gray
Write-Host "   .\manage-docker.ps1 logs [service]            # Show logs for all or specific service" -ForegroundColor Gray
Write-Host "   .\manage-docker.ps1 scale <service> -Replicas 3  # Scale a service" -ForegroundColor Gray
Write-Host "   .\manage-docker.ps1 clean                     # Clean unused Docker resources" -ForegroundColor Gray