# PowerShell script to start SendMyFiles application in Docker
# This script will:
# 1. Build the Docker images
# 2. Start all containers
# 3. Wait for services to be ready
# 4. Initialize the database

param(
    [switch]$SkipBuild = $false,
    [switch]$SkipInit = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SendMyFiles Docker Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
$dockerRunning = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and ensure Windows containers are enabled." -ForegroundColor Yellow
    exit 1
}
Write-Host "Docker is running." -ForegroundColor Green

# Check if Windows containers are enabled
$dockerVersion = docker version --format "{{.Server.Os}}"
if ($dockerVersion -ne "windows") {
    Write-Host "Warning: Not using Windows containers. Current OS: $dockerVersion" -ForegroundColor Yellow
    Write-Host "For .NET Framework apps, Windows containers are required." -ForegroundColor Yellow
    Write-Host "Switch to Windows containers in Docker Desktop." -ForegroundColor Yellow
}

# Build images if not skipped
if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "Building Docker images..." -ForegroundColor Yellow
    docker-compose -f docker-compose.windows.yml build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error building images!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Build completed." -ForegroundColor Green
}

# Start containers
Write-Host ""
Write-Host "Starting containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.windows.yml up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error starting containers!" -ForegroundColor Red
    exit 1
}

Write-Host "Containers started." -ForegroundColor Green

# Wait for SQL Server to be ready
Write-Host ""
Write-Host "Waiting for SQL Server to be ready (this may take 30-60 seconds)..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$sqlReady = $false

while ($attempt -lt $maxAttempts -and -not $sqlReady) {
    Start-Sleep -Seconds 2
    $attempt++
    $testResult = docker exec sendmyfiles-sqlserver sqlcmd -S localhost -U sa -P SendMyFiles@123 -Q "SELECT 1" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $sqlReady = $true
        Write-Host "SQL Server is ready!" -ForegroundColor Green
    } else {
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
}

if (-not $sqlReady) {
    Write-Host ""
    Write-Host "Warning: SQL Server may not be fully ready. Continuing anyway..." -ForegroundColor Yellow
}

# Initialize database if not skipped
if (-not $SkipInit) {
    Write-Host ""
    Write-Host "Initializing database..." -ForegroundColor Yellow
    & "$PSScriptRoot\init-database.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: Database initialization may have failed. Check logs." -ForegroundColor Yellow
    }
}

# Show status
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Services Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
docker-compose -f docker-compose.windows.yml ps

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Access Information" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Web Application:  http://localhost:8080" -ForegroundColor Green
Write-Host "MinIO Console:    http://localhost:9001" -ForegroundColor Green
Write-Host "MinIO API:        http://localhost:9000" -ForegroundColor Green
Write-Host "SQL Server:       localhost:1433" -ForegroundColor Green
Write-Host ""
Write-Host "MinIO Credentials:" -ForegroundColor Yellow
Write-Host "  Username: minioadmin" -ForegroundColor Gray
Write-Host "  Password: minioadmin" -ForegroundColor Gray
Write-Host ""
Write-Host "SQL Server Credentials:" -ForegroundColor Yellow
Write-Host "  Username: sa" -ForegroundColor Gray
Write-Host "  Password: SendMyFiles@123" -ForegroundColor Gray
Write-Host ""
Write-Host "To view logs:" -ForegroundColor Yellow
Write-Host "  docker-compose -f docker-compose.windows.yml logs -f" -ForegroundColor Cyan
Write-Host ""
Write-Host "To stop services:" -ForegroundColor Yellow
Write-Host "  docker-compose -f docker-compose.windows.yml down" -ForegroundColor Cyan
Write-Host ""

