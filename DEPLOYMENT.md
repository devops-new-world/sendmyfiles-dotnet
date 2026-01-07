# Server Deployment Guide for SendMyFiles

## Architecture Options

You have several deployment options depending on your requirements:

### Option 1: Single Server (Recommended for Small/Medium Scale)
**1 Machine Required**
- IIS Web Server + Application
- SQL Server (can be Express edition)
- MinIO (optional, can use local file storage)

**Best for:** Small teams, development, testing, low to medium traffic

### Option 2: Two Servers (Recommended for Production)
**2 Machines Required**
- **Server 1:** IIS Web Server + Application
- **Server 2:** SQL Server Database

**Best for:** Production environments, better performance, separation of concerns

### Option 3: Three Servers (High Availability)
**3 Machines Required**
- **Server 1:** IIS Web Server + Application
- **Server 2:** SQL Server Database
- **Server 3:** MinIO/S3 Storage Server

**Best for:** High traffic, enterprise deployments, maximum scalability

### Option 4: Cloud Services (Scalable)
**Cloud Services:**
- **Azure/AWS VM:** IIS Web Server
- **Azure SQL Database / AWS RDS:** Managed SQL Server
- **Azure Blob Storage / AWS S3 / MinIO:** Object Storage

**Best for:** Cloud deployments, auto-scaling, managed services

## Important Note: Database

⚠️ **This application uses Microsoft SQL Server (MSSQL), NOT MySQL.**

If you need MySQL support, the application would need to be modified to use MySQL instead of SQL Server.

## Single Server Deployment

### Requirements
- Windows Server 2016/2019/2022 or Windows 10/11
- IIS 10.0 or later
- .NET Framework 4.8
- SQL Server 2019/2022 (Express edition is sufficient)
- MinIO (optional) or use local file storage

### Step-by-Step Deployment

#### 1. Install Prerequisites

```powershell
# Install .NET Framework 4.8
# Download from: https://dotnet.microsoft.com/download/dotnet-framework/net48

# Install IIS and ASP.NET
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45
```

#### 2. Install SQL Server

Download and install SQL Server 2019/2022 Express or Developer edition:
- Download: https://www.microsoft.com/sql-server/sql-server-downloads
- During installation, choose "Mixed Mode Authentication"
- Set a strong SA password
- Enable TCP/IP protocol in SQL Server Configuration Manager

#### 3. Create Database

```sql
-- Connect to SQL Server using SQL Server Management Studio (SSMS)
-- Or use sqlcmd:

sqlcmd -S localhost -U sa -P YourPassword -i Database\Schema.sql
```

#### 4. Install MinIO (Optional)

**Option A: Download and Run**
```powershell
# Download MinIO from: https://min.io/download
# Extract and run:
.\minio.exe server C:\MinIO\Data --console-address ":9001"
```

**Option B: Run as Windows Service**
- Use NSSM (Non-Sucking Service Manager) to install MinIO as a service
- Or use MinIO's built-in service installation

**Option C: Skip MinIO**
- Set `UseMinio=false` in Web.config
- Files will be stored in `App_Data/Uploads` folder

#### 5. Publish Application

**Using Visual Studio:**
1. Right-click `SendMyFiles.Web` project
2. Select "Publish"
3. Choose "Folder" profile
4. Set publish location (e.g., `C:\inetpub\wwwroot\SendMyFiles`)
5. Click "Publish"

**Using MSBuild:**
```powershell
msbuild SendMyFiles.sln /p:Configuration=Release /p:DeployOnBuild=true /p:PublishUrl=C:\inetpub\wwwroot\SendMyFiles\
```

#### 6. Configure IIS

```powershell
# Create Application Pool
New-WebAppPool -Name "SendMyFilesAppPool"
Set-ItemProperty IIS:\AppPools\SendMyFilesAppPool -Name managedRuntimeVersion -Value "v4.0"
Set-ItemProperty IIS:\AppPools\SendMyFilesAppPool -Name processModel.identityType -Value ApplicationPoolIdentity

# Create Website
New-Website -Name "SendMyFiles" `
    -Port 80 `
    -PhysicalPath "C:\inetpub\wwwroot\SendMyFiles" `
    -ApplicationPool "SendMyFilesAppPool"

# Or create Application under Default Website
New-WebApplication -Name "SendMyFiles" `
    -Site "Default Web Site" `
    -PhysicalPath "C:\inetpub\wwwroot\SendMyFiles" `
    -ApplicationPool "SendMyFilesAppPool"
```

#### 7. Configure Web.config

Edit `C:\inetpub\wwwroot\SendMyFiles\Web.config`:

```xml
<connectionStrings>
  <add name="DefaultConnection" 
       connectionString="Server=localhost;Database=SendMyFiles;User Id=sa;Password=YourPassword;TrustServerCertificate=True;" />
</connectionStrings>

<appSettings>
  <!-- MinIO Configuration -->
  <add key="UseMinio" value="true" />
  <add key="MinioEndpoint" value="localhost:9000" />
  <!-- OR set to false for local storage -->
  <!-- <add key="UseMinio" value="false" /> -->
  
  <!-- Gmail SMTP -->
  <add key="SmtpServer" value="smtp.gmail.com" />
  <add key="SmtpPort" value="587" />
  <add key="SmtpUsername" value="your-email@gmail.com" />
  <add key="SmtpPassword" value="your-app-password" />
  
  <!-- Base URL -->
  <add key="BaseUrl" value="http://your-server-ip-or-domain" />
</appSettings>
```

#### 8. Set Permissions

```powershell
# Grant IIS_IUSRS permissions to App_Data folder
icacls "C:\inetpub\wwwroot\SendMyFiles\App_Data" /grant "IIS_IUSRS:(OI)(CI)F" /T

# If using local file storage
icacls "C:\inetpub\wwwroot\SendMyFiles\App_Data\Uploads" /grant "IIS_IUSRS:(OI)(CI)F" /T
```

#### 9. Test the Application

1. Open browser: `http://your-server-ip-or-domain`
2. Test file upload
3. Check email delivery
4. Verify file storage

## Two-Server Deployment

### Server 1: Web Server (IIS + Application)

Follow steps 1, 4, 5, 6, 7, 8 from Single Server deployment, but:

**Update Web.config:**
```xml
<connectionStrings>
  <add name="DefaultConnection" 
       connectionString="Server=Server2-IP;Database=SendMyFiles;User Id=sa;Password=YourPassword;TrustServerCertificate=True;" />
</connectionStrings>

<appSettings>
  <add key="MinioEndpoint" value="Server2-IP:9000" />
  <!-- OR use Server 1 for MinIO -->
</appSettings>
```

**Firewall Rules:**
- Allow inbound HTTP (port 80) and HTTPS (port 443)
- Allow outbound to SQL Server (port 1433)

### Server 2: Database Server (SQL Server)

1. Install SQL Server (same as Step 2 above)
2. Enable SQL Server Authentication
3. Configure firewall:
   ```powershell
   New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
   ```
4. Create database (run Schema.sql)
5. Create SQL login for web server:
   ```sql
   CREATE LOGIN [WebServerUser] WITH PASSWORD = 'StrongPassword123!';
   USE SendMyFiles;
   CREATE USER [WebServerUser] FOR LOGIN [WebServerUser];
   ALTER ROLE db_owner ADD MEMBER [WebServerUser];
   ```

**Update Web.config on Server 1:**
```xml
<connectionStrings>
  <add name="DefaultConnection" 
       connectionString="Server=Server2-IP;Database=SendMyFiles;User Id=WebServerUser;Password=StrongPassword123!;TrustServerCertificate=True;" />
</connectionStrings>
```

## Three-Server Deployment

### Server 1: Web Server
- IIS + Application
- Configure to connect to Server 2 (SQL) and Server 3 (MinIO)

### Server 2: Database Server
- SQL Server
- Configure firewall for Server 1 access

### Server 3: Storage Server
- MinIO or S3-compatible storage
- Configure access from Server 1

**Web.config on Server 1:**
```xml
<connectionStrings>
  <add name="DefaultConnection" 
       connectionString="Server=Server2-IP;Database=SendMyFiles;User Id=WebServerUser;Password=Password;TrustServerCertificate=True;" />
</connectionStrings>

<appSettings>
  <add key="MinioEndpoint" value="Server3-IP:9000" />
</appSettings>
```

## Cloud Deployment (Azure Example)

### Option A: Azure App Service + Azure SQL

1. **Create Azure SQL Database**
   - Portal → Create SQL Database
   - Configure firewall rules
   - Run Schema.sql

2. **Deploy to Azure App Service**
   - Create App Service (Windows, .NET Framework 4.8)
   - Deploy from Visual Studio or use Azure DevOps
   - Configure connection strings in App Settings

3. **Configure Azure Blob Storage** (instead of MinIO)
   - Create Storage Account
   - Update FileStorageService to use Azure Blob Storage

### Option B: Azure VM

1. Create Windows Server VM
2. Follow Single Server deployment steps
3. Configure Network Security Groups
4. Set up public IP and domain

## Network Requirements

### Ports to Open

**Web Server:**
- 80 (HTTP)
- 443 (HTTPS - recommended for production)

**SQL Server:**
- 1433 (SQL Server)

**MinIO:**
- 9000 (API)
- 9001 (Console - optional)

### Firewall Configuration

```powershell
# Web Server - Allow HTTP/HTTPS
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

# SQL Server - Allow from Web Server only
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow -RemoteAddress WebServerIP
```

## Security Best Practices

1. **Use HTTPS** - Install SSL certificate
2. **Strong Passwords** - For SQL Server and all services
3. **Least Privilege** - Use dedicated SQL user, not SA
4. **Firewall Rules** - Restrict access to necessary IPs only
5. **Regular Updates** - Keep Windows, IIS, SQL Server updated
6. **Backup Strategy** - Regular database and file backups
7. **Monitoring** - Set up logging and monitoring

## Monitoring and Maintenance

### IIS Logs
- Location: `C:\inetpub\logs\LogFiles`
- Enable failed request tracing for troubleshooting

### Application Logs
- Consider adding logging framework (NLog, Serilog)
- Monitor App_Data folder size

### Database Maintenance
- Regular backups
- Monitor database size
- Index maintenance

## Troubleshooting

### Application Not Loading
- Check IIS application pool is running
- Verify .NET Framework 4.8 is installed
- Check Windows Event Viewer for errors

### Database Connection Issues
- Verify SQL Server is running
- Check firewall rules
- Test connection: `sqlcmd -S ServerName -U UserName -P Password`

### File Upload Issues
- Check App_Data folder permissions
- Verify MinIO is accessible
- Check disk space

### Email Not Sending
- Verify SMTP credentials
- Check firewall allows outbound port 587
- Test SMTP connection separately

## Summary: Machine Requirements

| Deployment Type | Machines | What's on Each |
|----------------|----------|----------------|
| **Single Server** | 1 | IIS + App + SQL Server + MinIO (optional) |
| **Two Servers** | 2 | Server 1: IIS + App<br>Server 2: SQL Server |
| **Three Servers** | 3 | Server 1: IIS + App<br>Server 2: SQL Server<br>Server 3: MinIO/Storage |
| **Cloud** | 0-3 | Azure App Service + Azure SQL + Azure Storage |

**Minimum for Production:** 2 servers (Web + Database)  
**Recommended:** 2-3 servers for better performance and separation

