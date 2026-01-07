# SendMyFiles - Infrastructure and Architecture Documentation

## System Architecture Overview

### Application Architecture (3-Tier)

```
┌─────────────────────────────────────────────────────────┐
│                    Client Browser                        │
└────────────────────┬──────────────────────────────────────┘
                      │ HTTP/HTTPS (Port 80/443)
                      ▼
┌─────────────────────────────────────────────────────────┐
│              IIS Web Server (Port 80/443)               │
│  ┌──────────────────────────────────────────────────┐   │
│  │      SendMyFiles Web Application (.NET 4.8)      │   │
│  │  ┌──────────────┐  ┌──────────────┐            │   │
│  │  │ Controllers  │  │    Views     │            │   │
│  │  └──────────────┘  └──────────────┘            │   │
│  └──────────────────────────────────────────────────┘   │
└───────┬──────────────────────────┬──────────────────────┘
        │                          │
        │ Business Logic           │ Data Access
        ▼                          ▼
┌──────────────────┐      ┌──────────────────┐
│ Business Layer   │      │  Data Layer      │
│ - FileService    │◄─────┤  - Repositories  │
│ - EmailService   │      │  - DB Context    │
│ - StorageService │      └────────┬─────────┘
└────────┬─────────┘               │
         │                         │
         │                         ▼
         │              ┌──────────────────────┐
         │              │   SQL Server        │
         │              │   (MSSQL)           │
         │              │   Port 1433         │
         │              └──────────────────────┘
         │
         ▼
┌──────────────────────┐
│   MinIO / S3         │
│   Object Storage     │
│   Port 9000          │
└──────────────────────┘
```

### Application Layers

1. **Presentation Layer** (`SendMyFiles.Web`)
   - ASP.NET MVC web application
   - Controllers: `HomeController`, `FileController`
   - Views: Razor views for UI
   - Hosted on IIS

2. **Business Logic Layer** (`SendMyFiles.Business`)
   - `FileTransferService` - File transfer business logic
   - `EmailService` - Email notifications (Gmail SMTP)
   - `FileStorageService` - Storage abstraction (MinIO/S3 or local)

3. **Data Access Layer** (`SendMyFiles.Data`)
   - `UserRepository` - User data operations
   - `FileTransferRepository` - File transfer data operations
   - `DatabaseContext` - Entity Framework context

4. **Models Layer** (`SendMyFiles.Models`)
   - `User` - User entity model
   - `FileTransfer` - File transfer entity model

---

## Infrastructure Components

### 1. Web Server

**Technology**: IIS 10.0+ (Internet Information Services)

**Runtime**: .NET Framework 4.8

**Ports**: 
- **80** (HTTP)
- **443** (HTTPS - recommended for production)

**Requirements**:
- **Minimum**: 
  - Windows Server 2016 or Windows 10
  - IIS 10.0
  - .NET Framework 4.8
  - 2 GB RAM
  - 10 GB disk space
- **Recommended**: 
  - Windows Server 2019/2022
  - IIS 10.0+
  - .NET Framework 4.8
  - 4 GB RAM
  - 50 GB disk space (for local storage)

**Responsibilities**:
- Hosts the ASP.NET MVC web application
- Serves HTTP/HTTPS requests
- Manages application lifecycle
- Handles file uploads and downloads

---

### 2. Database Server

**Technology**: Microsoft SQL Server (MSSQL) - **NOT MySQL**

**Port**: **1433** (TCP)

**Database**: `SendMyFiles`

**Tables**: 
- `Users` - User accounts and quota information
- `FileTransfers` - File transfer records and metadata

**Options**:
- **SQL Server Express** (Free)
  - Up to 10 GB database size
  - 1 CPU socket
  - 1 GB RAM limit
  - Sufficient for small to medium deployments
- **SQL Server Standard/Enterprise** (Production)
  - Unlimited database size
  - Multiple CPUs
  - More RAM
  - Better for production environments

**Requirements**:
- **Minimum**: 
  - 2 GB RAM
  - 20 GB disk space
  - 1 CPU core
- **Recommended**: 
  - 4-8 GB RAM
  - 100 GB+ disk space
  - 2+ CPU cores

**Responsibilities**:
- Stores user accounts and authentication data
- Manages file transfer records
- Tracks user quotas (50 MB for free tier)
- Handles transaction management

---

### 3. Object Storage

**Primary Option**: MinIO (S3-compatible object storage)

**Ports**: 
- **9000** (API)
- **9001** (Console/Admin interface)

**Configuration**:
- Can run on same server as web app or separate server
- S3-compatible API
- Supports bucket-based organization

**Alternative Options**:
- **AWS S3** - Cloud-managed object storage
- **Azure Blob Storage** - Azure cloud storage
- **Local File Storage** - `App_Data/Uploads` folder (fallback)

**Requirements**:
- **MinIO**: 
  - 1 GB RAM minimum
  - Disk space depends on file storage needs
  - Can run on same server as web app
- **Cloud Storage**: 
  - Cloud-managed (no server maintenance)
  - Pay per storage used
  - High availability and scalability

**Responsibilities**:
- Stores uploaded files
- Provides secure file access
- Manages file lifecycle
- Handles file downloads

---

### 4. Email Service

**SMTP Server**: Gmail SMTP (smtp.gmail.com)

**Port**: **587** (TLS)

**Authentication**: Gmail App Password (requires 2-Factor Authentication)

**Configuration**:
- Requires Gmail account with 2FA enabled
- App Password generated from Google Account settings
- SSL/TLS encryption enabled

**Responsibilities**:
- Sends email notifications to recipients
- Includes download links with access tokens
- Handles email delivery failures

---

## Deployment Scenarios

### Scenario 1: Single Server (Development/Small Scale)

```
┌─────────────────────────────────────────┐
│         Single Windows Server           │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  IIS (Port 80)                   │  │
│  │  SendMyFiles Web App             │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  SQL Server (Port 1433)           │  │
│  │  SendMyFiles Database             │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  MinIO (Port 9000) - Optional     │  │
│  │  OR Local File Storage           │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

**Requirements**:
- Windows Server 2016/2019/2022
- IIS 10.0+
- .NET Framework 4.8
- SQL Server Express/Full
- MinIO (optional)

**Best For**:
- ✓ Development
- ✓ Testing
- ✓ Small teams (< 50 users)
- ✓ Low to medium traffic

---

### Scenario 2: Two Servers (Production Recommended)

```
┌─────────────────────────┐    ┌─────────────────────────┐
│   Server 1: Web Server  │    │  Server 2: DB Server    │
│                         │    │                         │
│  ┌───────────────────┐  │    │  ┌───────────────────┐  │
│  │ IIS (Port 80)     │  │    │  │ SQL Server        │  │
│  │ SendMyFiles App   │  │    │  │ (Port 1433)       │  │
│  └───────────────────┘  │    │  │ SendMyFiles DB    │  │
│                         │    │  └───────────────────┘  │
│  ┌───────────────────┐  │    │                         │
│  │ MinIO (Port 9000)  │  │    │                         │
│  │ OR Local Storage   │  │    │                         │
│  └───────────────────┘  │    │                         │
│                         │    │                         │
└───────────┬─────────────┘    └───────────┬─────────────┘
            │                               │
            └─────────── SQL ───────────────┘
            Connection (Port 1433)
```

**Requirements**:
- **Server 1**: Windows Server, IIS + Application, MinIO (optional)
- **Server 2**: Windows Server, SQL Server
- **Network**: Firewall rules for SQL Server access

**Best For**:
- ✓ Production environments
- ✓ Medium to high traffic
- ✓ Better performance
- ✓ Separation of concerns

---

### Scenario 3: Three Servers (Enterprise/High Availability)

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Server 1:    │    │ Server 2:    │    │ Server 3:    │
│ Web Server   │    │ DB Server    │    │ Storage      │
│              │    │              │    │              │
│ ┌──────────┐ │    │ ┌──────────┐ │    │ ┌──────────┐ │
│ │ IIS      │ │    │ │ SQL      │ │    │ │ MinIO    │ │
│ │ App      │ │    │ │ Server   │ │    │ │ S3       │ │
│ └──────────┘ │    │ └──────────┘ │    │ └──────────┘ │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                  │                   │
       └────────── SQL ───┴─── Storage ──────┘
```

**Requirements**:
- **Server 1**: Web Server (IIS + Application)
- **Server 2**: Database Server (SQL Server)
- **Server 3**: Storage Server (MinIO/S3)

**Best For**:
- ✓ Enterprise deployments
- ✓ High traffic
- ✓ Maximum scalability
- ✓ High availability
- ✓ Load distribution

---

### Scenario 4: Cloud Deployment (Azure Example)

```
┌─────────────────────────────────────────┐
│           Azure Cloud                   │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Azure App Service               │  │
│  │  (IIS + Application)             │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Azure SQL Database             │  │
│  │  (Managed SQL Server)            │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Azure Blob Storage              │  │
│  │  (Object Storage)                │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

**Benefits**:
- ✓ Auto-scaling
- ✓ Managed services
- ✓ High availability
- ✓ Backup & recovery
- ✓ Global distribution

**Cloud Options**:
- **Azure**: App Service + Azure SQL + Blob Storage
- **AWS**: EC2/ECS + RDS SQL Server + S3
- **Google Cloud**: Compute Engine + Cloud SQL + Cloud Storage

---

### Scenario 5: Docker/Containerized (Windows Containers)

```
┌─────────────────────────────────────────┐
│         Docker Compose Stack            │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  sendmyfiles-webapp              │  │
│  │  (Windows Container)             │  │
│  │  Port: 8080:80                   │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  sendmyfiles-sqlserver            │  │
│  │  (SQL Server 2022)               │  │
│  │  Port: 1433:1433                 │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  sendmyfiles-minio                │  │
│  │  Port: 9000:9000, 9001:9001      │  │
│  └──────────────────────────────────┘  │
│                                         │
│  Network: sendmyfiles-network          │
│  Volumes: sqlserver_data, minio_data   │
└─────────────────────────────────────────┘
```

**Note**: Requires Windows containers (Windows Server Core base image)

**Components**:
- **Web App Container**: ASP.NET Framework 4.8 on IIS
- **SQL Server Container**: Microsoft SQL Server 2022
- **MinIO Container**: MinIO object storage
- **Docker Network**: Bridge network for inter-container communication
- **Volumes**: Persistent storage for database and files

**Best For**:
- ✓ Development environments
- ✓ Consistent deployments
- ✓ Easy scaling
- ✓ Container orchestration (Kubernetes on Windows)

---

## Network Architecture

### Ports Required

| Service | Port | Protocol | Direction | Notes |
|---------|------|----------|-----------|-------|
| IIS/Web | 80 | TCP | Inbound | HTTP |
| IIS/Web | 443 | TCP | Inbound | HTTPS (recommended) |
| SQL Server | 1433 | TCP | Inbound | From Web Server only |
| MinIO API | 9000 | TCP | Inbound | From Web Server only |
| MinIO Console | 9001 | TCP | Inbound | Admin access (optional) |
| SMTP | 587 | TCP | Outbound | Email sending |

### Firewall Rules

**Web Server:**
```powershell
# Allow HTTP
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow

# Allow HTTPS
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
```

**Database Server:**
```powershell
# Allow SQL Server from Web Server only
New-NetFirewallRule -DisplayName "SQL Server" `
    -Direction Inbound -Protocol TCP -LocalPort 1433 `
    -Action Allow -RemoteAddress "WebServerIP"
```

**Storage Server:**
```powershell
# Allow MinIO from Web Server only
New-NetFirewallRule -DisplayName "MinIO" `
    -Direction Inbound -Protocol TCP -LocalPort 9000 `
    -Action Allow -RemoteAddress "WebServerIP"
```

---

## Infrastructure Summary

| Component | Technology | Port | Purpose |
|-----------|-----------|------|---------|
| **Web Server** | IIS 10.0+ | 80/443 | Hosts ASP.NET MVC application |
| **Application** | .NET Framework 4.8 | - | 3-tier application |
| **Database** | SQL Server (MSSQL) | 1433 | Stores users and file transfers |
| **Storage** | MinIO/S3 or Local | 9000 | File storage |
| **Email** | Gmail SMTP | 587 | Email notifications |
| **Container Platform** | Docker (Windows) | - | Containerization (optional) |

---

## Machine Requirements Summary

| Scenario | Machines | Components per Machine |
|----------|----------|------------------------|
| **Development** | 1 | IIS + App + SQL + Storage |
| **Small Production** | 1-2 | Server 1: IIS + App<br>Server 2: SQL (optional) |
| **Production** | 2 | Server 1: IIS + App<br>Server 2: SQL Server |
| **Enterprise** | 3+ | Server 1: IIS + App<br>Server 2: SQL Server<br>Server 3: Storage |
| **Cloud** | 0 (managed) | Azure App Service + Azure SQL + Azure Storage |
| **Docker** | 1+ | All services containerized |

**Minimum for Production**: 2 servers  
**Recommended**: 2-3 servers

---

## Load Balancing (Future Enhancement)

For high availability, you can add:

```
                    ┌─────────────┐
                    │ Load        │
                    │ Balancer    │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
   ┌─────────┐       ┌─────────┐       ┌─────────┐
   │ Web 1   │       │ Web 2   │       │ Web 3   │
   └─────────┘       └─────────┘       └─────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ SQL Server  │
                    │ (Clustered) │
                    └─────────────┘
```

**Benefits**:
- High availability
- Load distribution
- Failover capabilities
- Horizontal scaling

---

## Important Notes

### Database: SQL Server (MSSQL) - NOT MySQL

⚠️ **Important:** This application uses **Microsoft SQL Server (MSSQL)**, not MySQL.

**Why SQL Server?**
- Native .NET Framework integration
- Better performance with Entity Framework
- Windows ecosystem integration
- Free Express edition available

**If you need MySQL:**
- Would require code changes
- Replace SQL Server references with MySQL
- Use MySQL .NET connector
- Update connection strings

### Windows Containers Requirement

⚠️ **This application requires Windows containers** because it uses .NET Framework 4.8.

- Cannot run on Linux containers directly
- Requires Windows Server Core base image
- Docker Desktop must be in Windows container mode
- For Linux deployment, migration to .NET Core/ASP.NET Core would be required

---

## Related Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture diagrams and scenarios
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Step-by-step deployment guides
- **[DOCKER.md](DOCKER.md)** - Docker containerization guide
- **[SETUP.md](SETUP.md)** - Development setup instructions
- **[IIS-DEPLOYMENT.md](IIS-DEPLOYMENT.md)** - IIS-specific deployment guide

