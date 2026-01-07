# Running SendMyFiles on Docker

This guide explains how to run the SendMyFiles application using Docker containers.

## Important Notes

⚠️ **This application uses .NET Framework 4.8, which requires Windows containers.**

### Requirements:
- **Windows**: Docker Desktop with Windows containers enabled
- **Windows Server**: Docker Engine with Windows container support
- **Linux/Mac**: Cannot run Windows containers directly (requires Windows VM or remote Windows host)

## Prerequisites

1. **Install Docker Desktop** (Windows)
   - Download from: https://www.docker.com/products/docker-desktop
   - Enable Windows containers: Right-click Docker Desktop icon → Switch to Windows containers

2. **Verify Windows Containers**
   ```powershell
   docker version
   # Should show "OS/Arch: windows/amd64"
   ```

## Quick Start

### Option 1: Using Docker Compose (Recommended)

1. **Update Web.config for Docker environment**

   Edit `SendMyFiles.Web/Web.config` and update connection strings:

   ```xml
   <connectionStrings>
     <add name="DefaultConnection" 
          connectionString="Server=sqlserver;Database=SendMyFiles;User Id=sa;Password=SendMyFiles@123;TrustServerCertificate=True;" />
   </connectionStrings>
   
   <appSettings>
     <!-- MinIO endpoint - use service name from docker-compose -->
     <add key="MinioEndpoint" value="minio:9000" />
     
     <!-- Base URL for email links -->
     <add key="BaseUrl" value="http://localhost:8080" />
   </appSettings>
   ```

2. **Build and run all services**

   ```powershell
   # Build and start all containers
   docker-compose -f docker-compose.windows.yml up -d --build
   ```

3. **Initialize the database**

   The database container will start, but you need to run the schema script:

   ```powershell
   # Wait for SQL Server to be ready (about 30 seconds)
   Start-Sleep -Seconds 30
   
   # Run the schema script
   docker exec -i sendmyfiles-sqlserver sqlcmd -S localhost -U sa -P SendMyFiles@123 -i C:\init\schema.sql
   ```

   Or connect using SQL Server Management Studio:
   - Server: `localhost,1433`
   - Username: `sa`
   - Password: `SendMyFiles@123`

4. **Access the application**

   - Web Application: http://localhost:8080
   - MinIO Console: http://localhost:9001 (login: minioadmin/minioadmin)
   - SQL Server: localhost:1433

### Option 2: Manual Container Setup

#### 1. Start SQL Server

```powershell
docker run -d `
  --name sendmyfiles-sqlserver `
  -e "ACCEPT_EULA=Y" `
  -e "SA_PASSWORD=SendMyFiles@123" `
  -e "MSSQL_PID=Developer" `
  -p 1433:1433 `
  mcr.microsoft.com/mssql/server:2022-windows-latest
```

#### 2. Start MinIO

```powershell
docker run -d `
  --name sendmyfiles-minio `
  -p 9000:9000 `
  -p 9001:9001 `
  -e "MINIO_ROOT_USER=minioadmin" `
  -e "MINIO_ROOT_PASSWORD=minioadmin" `
  minio/minio server /data --console-address ":9001"
```

#### 3. Build Web Application

```powershell
# First, publish the application
# In Visual Studio: Right-click SendMyFiles.Web → Publish
# Or use MSBuild:
msbuild SendMyFiles.sln /p:Configuration=Release /p:PublishProfile=FolderProfile

# Then build Docker image
docker build -t sendmyfiles-webapp -f Dockerfile .
```

#### 4. Run Web Application

```powershell
docker run -d `
  --name sendmyfiles-webapp `
  -p 8080:80 `
  --link sendmyfiles-sqlserver:sqlserver `
  --link sendmyfiles-minio:minio `
  sendmyfiles-webapp
```

## Configuration for Docker

### Database Connection

In `Web.config`, use the container service name:

```xml
<connectionStrings>
  <add name="DefaultConnection" 
       connectionString="Server=sqlserver;Database=SendMyFiles;User Id=sa;Password=SendMyFiles@123;TrustServerCertificate=True;" />
</connectionStrings>
```

### MinIO Configuration

```xml
<appSettings>
  <add key="UseMinio" value="true" />
  <add key="MinioEndpoint" value="minio:9000" />
  <add key="MinioAccessKey" value="minioadmin" />
  <add key="MinioSecretKey" value="minioadmin" />
  <add key="MinioUseSSL" value="false" />
</appSettings>
```

### Gmail SMTP

Update with your Gmail credentials:

```xml
<add key="SmtpServer" value="smtp.gmail.com" />
<add key="SmtpPort" value="587" />
<add key="SmtpUsername" value="your-email@gmail.com" />
<add key="SmtpPassword" value="your-app-password" />
<add key="SmtpEnableSSL" value="true" />
```

## Docker Commands

### View running containers
```powershell
docker ps
```

### View logs
```powershell
# All services
docker-compose -f docker-compose.windows.yml logs

# Specific service
docker logs sendmyfiles-webapp
docker logs sendmyfiles-sqlserver
docker logs sendmyfiles-minio
```

### Stop services
```powershell
docker-compose -f docker-compose.windows.yml down
```

### Stop and remove volumes (clean slate)
```powershell
docker-compose -f docker-compose.windows.yml down -v
```

### Rebuild after code changes
```powershell
docker-compose -f docker-compose.windows.yml up -d --build
```

## Troubleshooting

### "Cannot connect to SQL Server"
- Wait for SQL Server to fully start (30-60 seconds)
- Verify container is running: `docker ps`
- Check logs: `docker logs sendmyfiles-sqlserver`
- Verify connection string uses service name `sqlserver` not `localhost`

### "MinIO connection failed"
- Verify MinIO container is running
- Check network connectivity between containers
- Use service name `minio` in configuration, not `localhost`

### "Application not accessible"
- Verify port 8080 is not in use
- Check Windows Firewall settings
- Verify container is running: `docker ps`
- Check logs: `docker logs sendmyfiles-webapp`

### "Windows containers not available"
- Ensure Docker Desktop is set to Windows containers mode
- On Windows Server, ensure container feature is installed
- Verify with: `docker version`

## Production Considerations

### Security
1. **Change default passwords** in docker-compose.yml
2. **Use secrets management** for sensitive data
3. **Enable SSL/TLS** for all services
4. **Use environment variables** instead of hardcoded values
5. **Restrict network access** between containers

### Performance
1. **Resource limits**: Add CPU and memory limits to containers
2. **Volume mounts**: Use named volumes for persistent data
3. **Health checks**: Monitor container health
4. **Logging**: Configure centralized logging

### Example Production docker-compose.yml

```yaml
services:
  webapp:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
    environment:
      - ConnectionStrings__DefaultConnection=${DB_CONNECTION_STRING}
      - AppSettings__SmtpPassword=${SMTP_PASSWORD}
```

## Alternative: Linux Containers

To run on Linux containers, you would need to:
1. Migrate from .NET Framework to .NET Core/ASP.NET Core
2. Update all dependencies
3. Modify code for cross-platform compatibility

This is a significant refactoring effort but would allow running on Linux containers.

## Support

For issues specific to:
- **Docker**: Check Docker Desktop logs and container logs
- **SQL Server**: Check SQL Server container logs
- **Application**: Check web application logs in container
- **Network**: Verify containers are on the same network

