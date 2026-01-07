# Docker Quick Start Guide

## Prerequisites

✅ **Windows 10/11 or Windows Server**  
✅ **Docker Desktop** with Windows containers enabled  
✅ **PowerShell** (for scripts)

## Quick Start (3 Steps)

### 1. Enable Windows Containers

Right-click Docker Desktop icon → **Switch to Windows containers**

Verify:
```powershell
docker version
# Should show: OS/Arch: windows/amd64
```

### 2. Update Configuration

Copy `Web.config.docker` to `SendMyFiles.Web/Web.config` and update:
- Gmail SMTP credentials (if using email)
- Any custom settings

### 3. Run the Application

```powershell
# Option A: Use the automated script (recommended)
.\docker-start.ps1

# Option B: Manual steps
docker-compose -f docker-compose.windows.yml up -d --build
.\init-database.ps1
```

## Access the Application

- **Web App**: http://localhost:8080
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)
- **SQL Server**: localhost:1433 (sa/SendMyFiles@123)

## Common Commands

```powershell
# View logs
docker-compose -f docker-compose.windows.yml logs -f

# Stop services
docker-compose -f docker-compose.windows.yml down

# Stop and remove all data
docker-compose -f docker-compose.windows.yml down -v

# Restart a service
docker-compose -f docker-compose.windows.yml restart webapp

# View running containers
docker ps
```

## Troubleshooting

### "Windows containers not available"
- Ensure Docker Desktop is in Windows container mode
- Restart Docker Desktop

### "Cannot connect to database"
- Wait 30-60 seconds for SQL Server to start
- Run: `.\init-database.ps1` again

### "Port already in use"
- Change ports in `docker-compose.windows.yml`
- Or stop the service using the port

## Next Steps

1. **Configure Gmail SMTP** in `Web.config`
2. **Test file upload** at http://localhost:8080
3. **Check email** for download link

For detailed information, see [DOCKER.md](DOCKER.md)

