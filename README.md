# SendMyFiles - 3-Tier File Sharing Application

A .NET Framework-based file sharing application that allows users to exchange files via email notifications.

## Features

- **File Upload & Sharing**: Upload files and share them with recipients via email
- **Email Notifications**: Automatic email notifications to recipients with download links
- **Quota Management**: 
  - Free tier: 50 MB quota limit
  - Premium tier: Unlimited (currently disabled)
- **Secure Access**: Unique access tokens for each file transfer
- **MinIO/S3 Integration**: Store files in MinIO or AWS S3
- **Gmail SMTP**: Send notifications via Gmail SMTP

## Architecture

This is a 3-tier application:

1. **Presentation Layer** (`SendMyFiles.Web`): ASP.NET MVC web application
2. **Business Logic Layer** (`SendMyFiles.Business`): Contains business logic and services
3. **Data Access Layer** (`SendMyFiles.Data`): Database repositories and data access

## Prerequisites

- .NET Framework 4.8
- SQL Server (MSSQL)
- MinIO (optional, can use local file storage)
- Gmail account with App Password for SMTP

## Setup Instructions

### 1. Database Setup

Run the SQL script in `Database/Schema.sql` to create the database and tables:

```sql
-- Execute Database/Schema.sql in SQL Server Management Studio
```

### 2. Configuration

Edit `SendMyFiles.Web/Web.config` and update the following settings:

#### Database Connection
```xml
<add key="DefaultConnection" value="Server=localhost;Database=SendMyFiles;Integrated Security=True;TrustServerCertificate=True;" />
```

#### MinIO Configuration (Optional)
```xml
<add key="UseMinio" value="true" />
<add key="MinioEndpoint" value="localhost:9000" />
<add key="MinioAccessKey" value="minioadmin" />
<add key="MinioSecretKey" value="minioadmin" />
<add key="MinioUseSSL" value="false" />
<add key="StorageBucketName" value="sendmyfiles" />
```

If `UseMinio` is set to `false`, files will be stored locally in `App_Data/Uploads`.

#### Gmail SMTP Configuration
```xml
<add key="SmtpServer" value="smtp.gmail.com" />
<add key="SmtpPort" value="587" />
<add key="SmtpUsername" value="your-email@gmail.com" />
<add key="SmtpPassword" value="your-app-password" />
<add key="SmtpEnableSSL" value="true" />
<add key="SmtpFromEmail" value="your-email@gmail.com" />
```

**Note**: For Gmail, you need to:
1. Enable 2-Factor Authentication
2. Generate an App Password: https://myaccount.google.com/apppasswords
3. Use the App Password (not your regular password) in the configuration

#### Application Base URL
```xml
<add key="BaseUrl" value="http://localhost:8080" />
```

### 3. Install NuGet Packages

The following packages are required:
- Minio (4.0.3) - for MinIO integration
- Microsoft.AspNet.Mvc (5.2.7) - for MVC framework

You can install them via NuGet Package Manager or restore packages automatically when building the solution.

### 4. Build and Run

1. Open the solution in Visual Studio
2. Restore NuGet packages
3. Build the solution (Ctrl+Shift+B)
4. Set `SendMyFiles.Web` as the startup project
5. Run the application (F5)

The application will be available at `http://localhost:8080`

## Usage

1. **Upload a File**:
   - Enter your email address
   - Enter the recipient's email address
   - Select a file to upload
   - Click "Upload & Send File"

2. **Receive Files**:
   - Recipients will receive an email with a download link
   - Click the link to download the file
   - Files expire after 7 days

## Project Structure

```
SendMyFiles/
├── SendMyFiles.Web/          # Presentation Layer (ASP.NET MVC)
│   ├── Controllers/
│   ├── Views/
│   └── Web.config
├── SendMyFiles.Business/     # Business Logic Layer
│   └── Services/
│       ├── FileStorageService.cs
│       ├── EmailService.cs
│       └── FileTransferService.cs
├── SendMyFiles.Data/         # Data Access Layer
│   └── Repositories/
│       ├── UserRepository.cs
│       └── FileTransferRepository.cs
├── SendMyFiles.Models/       # Shared Models
│   ├── User.cs
│   └── FileTransfer.cs
└── Database/
    └── Schema.sql
```

## Features in Detail

### Free Tier
- 50 MB total quota
- Quota is tracked per user (by email)
- Visual quota indicator on the upload page

### Premium Tier
- Unlimited storage (currently disabled in UI)
- Can be enabled by changing user type in database

### File Storage
- Supports MinIO (S3-compatible) object storage
- Falls back to local file system if MinIO is not configured
- Files are stored with unique identifiers

### Email Notifications
- Automatic email sent to recipient upon file upload
- Contains download link with unique access token
- Link expires after 7 days

## Troubleshooting

### Email Not Sending
- Verify Gmail SMTP credentials
- Ensure App Password is used (not regular password)
- Check firewall/network settings

### MinIO Connection Issues
- Verify MinIO is running
- Check endpoint, access key, and secret key
- Set `UseMinio` to `false` to use local storage instead

### Database Connection Issues
- Verify SQL Server is running
- Check connection string in Web.config
- Ensure database exists and schema is created

## Deployment Options

### Docker Deployment
This application can run in Docker containers. See [DOCKER.md](DOCKER.md) for detailed instructions.

**Quick Start with Docker:**
```powershell
# Start all services
.\docker-start.ps1

# Or manually:
docker-compose -f docker-compose.windows.yml up -d --build
.\init-database.ps1
```

**Note:** This application requires Windows containers because it uses .NET Framework 4.8.

### IIS Server Deployment
For production server deployment, see:
- **[IIS-DEPLOYMENT.md](IIS-DEPLOYMENT.md)** - Step-by-step IIS deployment guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment scenarios
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and machine requirements

**Quick Summary:**
- **Minimum:** 1 server (IIS + SQL Server + Storage)
- **Recommended:** 2 servers (Web Server + Database Server)
- **Enterprise:** 3 servers (Web + Database + Storage)
- **Database:** Microsoft SQL Server (MSSQL), NOT MySQL

## License

This project is provided as-is for educational purposes.

