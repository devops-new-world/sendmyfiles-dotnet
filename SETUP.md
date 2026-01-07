# Setup Guide for SendMyFiles

## Quick Start

### 1. Prerequisites Installation

#### Install .NET Framework 4.8 Developer Pack
- Download from: https://dotnet.microsoft.com/download/dotnet-framework/net48
- Install the Developer Pack

#### Install SQL Server
- Download SQL Server Express or Developer Edition
- Or use SQL Server LocalDB (included with Visual Studio)

#### Install MinIO (Optional)
If you want to use MinIO for file storage:
```bash
# Using Docker
docker run -p 9000:9000 -p 9001:9001 \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  minio/minio server /data --console-address ":9001"
```

Or download from: https://min.io/download

### 2. Database Setup

1. Open SQL Server Management Studio (SSMS) or use `sqlcmd`
2. Run the script: `Database/Schema.sql`
3. This will create:
   - Database: `SendMyFiles`
   - Tables: `Users`, `FileTransfers`

### 3. Configure the Application

Edit `SendMyFiles.Web/Web.config`:

#### Database Connection String
```xml
<connectionStrings>
  <add name="DefaultConnection" 
       connectionString="Server=localhost;Database=SendMyFiles;Integrated Security=True;TrustServerCertificate=True;" />
</connectionStrings>
```

For SQL Server Authentication:
```xml
<add name="DefaultConnection" 
     connectionString="Server=localhost;Database=SendMyFiles;User Id=sa;Password=YourPassword;TrustServerCertificate=True;" />
```

#### Gmail SMTP Configuration

1. Enable 2-Factor Authentication on your Gmail account
2. Generate an App Password:
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Enter "SendMyFiles" as the name
   - Copy the generated 16-character password

3. Update Web.config:
```xml
<add key="SmtpServer" value="smtp.gmail.com" />
<add key="SmtpPort" value="587" />
<add key="SmtpUsername" value="your-email@gmail.com" />
<add key="SmtpPassword" value="your-16-char-app-password" />
<add key="SmtpEnableSSL" value="true" />
<add key="SmtpFromEmail" value="your-email@gmail.com" />
```

#### MinIO Configuration (Optional)

If using MinIO:
```xml
<add key="UseMinio" value="true" />
<add key="MinioEndpoint" value="localhost:9000" />
<add key="MinioAccessKey" value="minioadmin" />
<add key="MinioSecretKey" value="minioadmin" />
<add key="MinioUseSSL" value="false" />
<add key="StorageBucketName" value="sendmyfiles" />
```

If NOT using MinIO (local file storage):
```xml
<add key="UseMinio" value="false" />
<add key="LocalStoragePath" value="~/App_Data/Uploads" />
```

#### Application Base URL
```xml
<add key="BaseUrl" value="http://localhost:8080" />
```

### 4. Build and Run

#### Using Visual Studio:
1. Open `SendMyFiles.sln`
2. Restore NuGet packages (right-click solution → Restore NuGet Packages)
3. Build the solution (Ctrl+Shift+B)
4. Set `SendMyFiles.Web` as startup project
5. Press F5 to run

#### Using Command Line:
```bash
# Restore NuGet packages
nuget restore SendMyFiles.sln

# Build
msbuild SendMyFiles.sln /p:Configuration=Debug

# Run (requires IIS Express or local IIS)
```

### 5. Access the Application

Open your browser and navigate to:
```
http://localhost:8080
```

## Testing

### Test File Upload:
1. Enter your email address
2. Enter a recipient email address
3. Select a file (under 50 MB for free tier)
4. Click "Upload & Send File"
5. Check the recipient's email for the download link

### Test File Download:
1. Click the download link from the email
2. File should download automatically

## Troubleshooting

### "Cannot connect to database"
- Verify SQL Server is running
- Check connection string in Web.config
- Ensure database exists (run Schema.sql)

### "Email not sending"
- Verify Gmail App Password is correct (16 characters, no spaces)
- Check that 2FA is enabled on Gmail account
- Verify SMTP settings in Web.config
- Check firewall/network settings

### "MinIO connection failed"
- Verify MinIO is running: `http://localhost:9000`
- Check MinIO credentials
- Set `UseMinio` to `false` to use local storage instead

### "File upload fails"
- Check file size (free tier: 50 MB limit)
- Verify storage path exists and is writable
- Check application logs for detailed errors

## Production Deployment

### Important Security Considerations:
1. **Never commit Web.config with real credentials** - Use Web.Release.config or environment variables
2. **Use HTTPS** - Update BaseUrl to use HTTPS
3. **Secure MinIO** - Use SSL and strong credentials
4. **Database Security** - Use SQL Server Authentication with strong passwords
5. **File Size Limits** - Adjust `maxRequestLength` in Web.config if needed
6. **Email Security** - Consider using a dedicated email service (SendGrid, AWS SES, etc.)

### IIS Deployment:
1. Publish the Web project
2. Create an Application Pool (use .NET Framework 4.8)
3. Create a new Website in IIS
4. Point to the published folder
5. Configure connection strings and app settings
6. Ensure App_Data folder has write permissions

