# PowerShell script to initialize database in Docker container
# Run this after starting the SQL Server container

param(
    [string]$ContainerName = "sendmyfiles-sqlserver",
    [string]$SaPassword = "SendMyFiles@123",
    [int]$WaitSeconds = 30
)

Write-Host "Waiting for SQL Server to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds $WaitSeconds

Write-Host "Checking if SQL Server container is running..." -ForegroundColor Yellow
$container = docker ps --filter "name=$ContainerName" --format "{{.Names}}"
if (-not $container) {
    Write-Host "Error: Container '$ContainerName' is not running!" -ForegroundColor Red
    Write-Host "Please start the container first using:" -ForegroundColor Yellow
    Write-Host "  docker-compose -f docker-compose.windows.yml up -d sqlserver" -ForegroundColor Cyan
    exit 1
}

Write-Host "Container found: $container" -ForegroundColor Green

Write-Host "Testing SQL Server connection..." -ForegroundColor Yellow
$testQuery = "SELECT 1"
$testResult = docker exec $ContainerName sqlcmd -S localhost -U sa -P $SaPassword -Q $testQuery 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "SQL Server is not ready yet. Waiting additional 30 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    $testResult = docker exec $ContainerName sqlcmd -S localhost -U sa -P $SaPassword -Q $testQuery 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Cannot connect to SQL Server!" -ForegroundColor Red
        Write-Host $testResult -ForegroundColor Red
        exit 1
    }
}

Write-Host "SQL Server is ready!" -ForegroundColor Green

Write-Host "Creating database if it doesn't exist..." -ForegroundColor Yellow
$createDbQuery = @"
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SendMyFiles')
BEGIN
    CREATE DATABASE SendMyFiles;
    PRINT 'Database SendMyFiles created successfully.';
END
ELSE
BEGIN
    PRINT 'Database SendMyFiles already exists.';
END
"@

docker exec -i $ContainerName sqlcmd -S localhost -U sa -P $SaPassword -Q $createDbQuery

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error creating database!" -ForegroundColor Red
    exit 1
}

Write-Host "Running schema script..." -ForegroundColor Yellow

# Read and execute the schema file
$schemaPath = Join-Path $PSScriptRoot "Database\Schema.sql"
if (-not (Test-Path $schemaPath)) {
    Write-Host "Error: Schema file not found at $schemaPath" -ForegroundColor Red
    exit 1
}

# Execute schema script
Get-Content $schemaPath | docker exec -i $ContainerName sqlcmd -S localhost -U sa -P $SaPassword -d SendMyFiles

if ($LASTEXITCODE -eq 0) {
    Write-Host "Database initialized successfully!" -ForegroundColor Green
    Write-Host "You can now start the web application." -ForegroundColor Green
} else {
    Write-Host "Error initializing database!" -ForegroundColor Red
    exit 1
}

