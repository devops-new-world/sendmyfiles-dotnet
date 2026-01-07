# IIS Deployment Guide - Step by Step

This guide provides detailed instructions for deploying SendMyFiles to IIS on Windows Server.

## Prerequisites Checklist

- [ ] Windows Server 2016/2019/2022 or Windows 10/11
- [ ] Administrator access
- [ ] SQL Server installed (Express or Full edition)
- [ ] .NET Framework 4.8 installed
- [ ] IIS installed and configured
- [ ] MinIO installed (optional)

## Step 1: Install .NET Framework 4.8

1. Download from: https://dotnet.microsoft.com/download/dotnet-framework/net48
2. Run the installer
3. Restart if prompted

Verify installation:
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" | Select-Object Version
```

## Step 2: Install and Configure IIS

### Install IIS with Required Features

```powershell
# Run PowerShell as Administrator

# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Install ASP.NET 4.8
Install-WindowsFeature -Name Web-Asp-Net45

# Install additional required features
Install-WindowsFeature -Name Web-Mgmt-Console
Install-WindowsFeature -Name Web-Mgmt-Service
Install-WindowsFeature -Name Web-Metabase
Install-WindowsFeature -Name Web-WMI
```

### Verify IIS Installation

1. Open browser: `http://localhost`
2. You should see IIS welcome page

## Step 3: Install SQL Server

### Download and Install

1. Download SQL Server 2019/2022 Express or Developer:
   - Express (Free): https://www.microsoft.com/sql-server/sql-server-downloads
   - Developer (Free for development): Same link

2. Run installer:
   - Choose "Basic" installation for Express
   - Or "Custom" for more control
   - **Important:** Select "Mixed Mode Authentication"
   - Set a strong SA password
   - Note the password for later

3. Install SQL Server Management Studio (SSMS):
   - Download: https://docs.microsoft.com/sql/ssms/download-sql-server-management-studio-ssms

### Configure SQL Server

1. Open **SQL Server Configuration Manager**
2. Go to **SQL Server Network Configuration** → **Protocols for MSSQLSERVER**
3. Enable **TCP/IP**
4. Right-click **TCP/IP** → Properties → IP Addresses tab
5. Set **TCP Port** to **1433** for all IP addresses
6. Restart SQL Server service

### Create Firewall Rule

```powershell
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
```

## Step 4: Create Database

### Option A: Using SSMS (Recommended)

1. Open **SQL Server Management Studio**
2. Connect to server:
   - Server name: `localhost` or `.\SQLEXPRESS` (for Express)
   - Authentication: **SQL Server Authentication**
   - Login: `sa`
   - Password: (the password you set during installation)

3. Open **Database/Schema.sql** file
4. Execute the script (F5)
5. Verify database created:
   ```sql
   USE SendMyFiles;
   SELECT * FROM Users;
   ```

### Option B: Using Command Line

```powershell
# Navigate to project directory
cd C:\path\to\sendmyfiles-dotnet

# Run schema script
sqlcmd -S localhost -U sa -P YourPassword -i Database\Schema.sql
```

## Step 5: Install MinIO (Optional)

### Option A: Download and Run Manually

1. Download MinIO: https://min.io/download
2. Extract to `C:\MinIO`
3. Create data folder: `C:\MinIO\Data`
4. Run:
   ```powershell
   cd C:\MinIO
   .\minio.exe server C:\MinIO\Data --console-address ":9001"
   ```
5. Access console: http://localhost:9001
   - Username: `minioadmin`
   - Password: `minioadmin`

### Option B: Install as Windows Service

1. Download NSSM: https://nssm.cc/download
2. Extract NSSM
3. Install MinIO as service:
   ```powershell
   nssm install MinIO "C:\MinIO\minio.exe" "server C:\MinIO\Data --console-address :9001"
   nssm set MinIO AppEnvironmentExtra MINIO_ROOT_USER=minioadmin MINIO_ROOT_PASSWORD=minioadmin
   nssm start MinIO
   ```

### Option C: Skip MinIO

- Set `UseMinio=false` in Web.config
- Files will be stored locally in `App_Data/Uploads`

## Step 6: Build and Publish Application

### Option A: Using Visual Studio

1. Open `SendMyFiles.sln` in Visual Studio
2. Right-click `SendMyFiles.Web` project
3. Select **Publish**
4. Choose **Folder** profile
5. Set publish location: `C:\inetpub\wwwroot\SendMyFiles`
6. Click **Publish**

### Option B: Using MSBuild

```powershell
# Navigate to solution directory
cd C:\path\to\sendmyfiles-dotnet

# Build and publish
msbuild SendMyFiles.sln /p:Configuration=Release /p:DeployOnBuild=true /p:PublishUrl=C:\inetpub\wwwroot\SendMyFiles\
```

### Option C: Manual Copy

1. Build solution in Visual Studio (Release mode)
2. Copy files from `SendMyFiles.Web\bin\Release` to `C:\inetpub\wwwroot\SendMyFiles`
3. Copy Views, Web.config, Global.asax, etc.

## Step 7: Configure Web.config

Edit `C:\inetpub\wwwroot\SendMyFiles\Web.config`:

### Database Connection

```xml
<connectionStrings>
  <!-- For SQL Server Express -->
  <add name="DefaultConnection" 
       connectionString="Server=localhost\SQLEXPRESS;Database=SendMyFiles;User Id=sa;Password=YourPassword;TrustServerCertificate=True;" />
  
  <!-- For SQL Server Full -->
  <!-- <add name="DefaultConnection" 
       connectionString="Server=localhost;Database=SendMyFiles;User Id=sa;Password=YourPassword;TrustServerCertificate=True;" /> -->
</connectionStrings>
```

### MinIO Configuration

```xml
<appSettings>
  <!-- If using MinIO -->
  <add key="UseMinio" value="true" />
  <add key="MinioEndpoint" value="localhost:9000" />
  <add key="MinioAccessKey" value="minioadmin" />
  <add key="MinioSecretKey" value="minioadmin" />
  
  <!-- OR use local storage -->
  <!-- <add key="UseMinio" value="false" /> -->
  <!-- <add key="LocalStoragePath" value="~/App_Data/Uploads" /> -->
</appSettings>
```

### Gmail SMTP Configuration

```xml
<appSettings>
  <add key="SmtpServer" value="smtp.gmail.com" />
  <add key="SmtpPort" value="587" />
  <add key="SmtpUsername" value="your-email@gmail.com" />
  <add key="SmtpPassword" value="your-16-char-app-password" />
  <add key="SmtpEnableSSL" value="true" />
  <add key="SmtpFromEmail" value="your-email@gmail.com" />
</appSettings>
```

### Base URL

```xml
<appSettings>
  <!-- Replace with your server's IP or domain -->
  <add key="BaseUrl" value="http://your-server-ip-or-domain" />
</appSettings>
```

## Step 8: Configure IIS

### Create Application Pool

```powershell
# Run PowerShell as Administrator

# Create new application pool
New-WebAppPool -Name "SendMyFilesAppPool"

# Configure .NET Framework version
Set-ItemProperty IIS:\AppPools\SendMyFilesAppPool -Name managedRuntimeVersion -Value "v4.0"

# Set identity (use ApplicationPoolIdentity for security)
Set-ItemProperty IIS:\AppPools\SendMyFilesAppPool -Name processModel.identityType -Value ApplicationPoolIdentity

# Set to start automatically
Set-ItemProperty IIS:\AppPools\SendMyFilesAppPool -Name startMode -Value AlwaysRunning
```

### Create Website

**Option A: New Website (Recommended for Production)**

```powershell
New-Website -Name "SendMyFiles" `
    -Port 80 `
    -PhysicalPath "C:\inetpub\wwwroot\SendMyFiles" `
    -ApplicationPool "SendMyFilesAppPool"
```

**Option B: Application under Default Website**

```powershell
New-WebApplication -Name "SendMyFiles" `
    -Site "Default Web Site" `
    -PhysicalPath "C:\inetpub\wwwroot\SendMyFiles" `
    -ApplicationPool "SendMyFilesAppPool"
```

### Configure Website Settings

1. Open **IIS Manager** (`inetmgr`)
2. Navigate to your website/application
3. Double-click **Authentication**
4. Disable **Anonymous Authentication** (if you want authentication)
5. Or keep it enabled for public access

## Step 9: Set Folder Permissions

```powershell
# Grant IIS application pool permissions
$appPoolName = "SendMyFilesAppPool"
$appPoolIdentity = "IIS AppPool\$appPoolName"
$appPath = "C:\inetpub\wwwroot\SendMyFiles"

# Grant permissions to application folder
icacls $appPath /grant "${appPoolIdentity}:(OI)(CI)RX" /T

# Grant full permissions to App_Data (for file uploads)
icacls "$appPath\App_Data" /grant "${appPoolIdentity}:(OI)(CI)F" /T

# Create Uploads folder if it doesn't exist
New-Item -ItemType Directory -Force -Path "$appPath\App_Data\Uploads" | Out-Null
icacls "$appPath\App_Data\Uploads" /grant "${appPoolIdentity}:(OI)(CI)F" /T
```

## Step 10: Configure Firewall

```powershell
# Allow HTTP traffic
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow

# Allow HTTPS (if using SSL)
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
```

## Step 11: Test the Application

1. Open browser: `http://localhost` or `http://your-server-ip`
2. You should see the SendMyFiles upload page
3. Test file upload:
   - Enter your email
   - Enter recipient email
   - Select a file
   - Click upload
4. Check recipient's email for download link
5. Test download link

## Step 12: Configure SSL (HTTPS) - Recommended for Production

### Option A: Self-Signed Certificate (Testing)

```powershell
# Create self-signed certificate
$cert = New-SelfSignedCertificate -DnsName "your-domain.com" -CertStoreLocation "cert:\LocalMachine\My"

# Bind to website
New-WebBinding -Name "SendMyFiles" -Protocol https -Port 443
$binding = Get-WebBinding -Name "SendMyFiles" -Protocol https
$binding.AddSslCertificate($cert.Thumbprint, "My")
```

### Option B: Let's Encrypt (Free, Production)

1. Install win-acme: https://www.win-acme.com/
2. Run and follow wizard to get certificate
3. Certificate will be automatically configured

### Option C: Commercial Certificate

1. Purchase SSL certificate
2. Install in Windows Certificate Store
3. Bind to website in IIS Manager

## Troubleshooting

### Application Not Loading

1. **Check Application Pool:**
   ```powershell
   Get-WebAppPoolState -Name "SendMyFilesAppPool"
   ```
   - Should show "Started"
   - If not, start it: `Start-WebAppPool -Name "SendMyFilesAppPool"`

2. **Check Windows Event Viewer:**
   - Windows Logs → Application
   - Look for errors

3. **Check IIS Logs:**
   - Location: `C:\inetpub\logs\LogFiles\W3SVC1`

4. **Enable Detailed Errors:**
   - IIS Manager → Website → Error Pages
   - Edit Feature Settings → Detailed Errors

### Database Connection Errors

1. **Verify SQL Server is running:**
   ```powershell
   Get-Service MSSQLSERVER
   ```

2. **Test connection:**
   ```powershell
   sqlcmd -S localhost -U sa -P YourPassword -Q "SELECT @@VERSION"
   ```

3. **Check connection string in Web.config**

### File Upload Errors

1. **Check folder permissions:**
   ```powershell
   icacls "C:\inetpub\wwwroot\SendMyFiles\App_Data"
   ```

2. **Check disk space:**
   ```powershell
   Get-PSDrive C
   ```

3. **Check maxRequestLength in Web.config:**
   ```xml
   <httpRuntime maxRequestLength="1048576" />
   ```

### Email Not Sending

1. **Test SMTP connection:**
   ```powershell
   Test-NetConnection smtp.gmail.com -Port 587
   ```

2. **Check firewall allows outbound port 587**

3. **Verify Gmail App Password is correct**

## Maintenance

### Regular Tasks

1. **Backup Database:**
   ```sql
   BACKUP DATABASE SendMyFiles TO DISK = 'C:\Backups\SendMyFiles.bak';
   ```

2. **Monitor Disk Space:**
   - Check App_Data folder size
   - Clean up old files if needed

3. **Update Application:**
   - Publish new version
   - Stop app pool
   - Copy files
   - Start app pool

4. **Monitor Logs:**
   - IIS logs
   - Windows Event Viewer
   - Application logs (if implemented)

## Summary

✅ **Single Server Setup:**
- 1 Windows Server
- IIS + Application
- SQL Server (Express is fine)
- MinIO (optional)

✅ **Production Setup:**
- 2 Servers minimum (Web + Database)
- 3 Servers recommended (Web + Database + Storage)

✅ **Database:** Microsoft SQL Server (MSSQL), NOT MySQL

The application is now ready to use!

