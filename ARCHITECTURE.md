# SendMyFiles Architecture and Deployment Scenarios

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Client Browser                        │
└────────────────────┬──────────────────────────────────────┘
                      │ HTTP/HTTPS
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

Requirements:
- Windows Server 2016/2019/2022
- IIS 10.0+
- .NET Framework 4.8
- SQL Server Express/Full
- MinIO (optional)

Best For:
✓ Development
✓ Testing
✓ Small teams (< 50 users)
✓ Low to medium traffic
```

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

Requirements:
Server 1:
- Windows Server
- IIS + Application
- MinIO (optional)

Server 2:
- Windows Server
- SQL Server

Network:
- Firewall rules for SQL Server access

Best For:
✓ Production environments
✓ Medium to high traffic
✓ Better performance
✓ Separation of concerns
```

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

Requirements:
Server 1: Web Server
Server 2: Database Server
Server 3: Storage Server (MinIO/S3)

Best For:
✓ Enterprise deployments
✓ High traffic
✓ Maximum scalability
✓ High availability
✓ Load distribution
```

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

Benefits:
✓ Auto-scaling
✓ Managed services
✓ High availability
✓ Backup & recovery
✓ Global distribution
```

## Component Details

### Web Server Requirements

**Minimum:**
- Windows Server 2016 or Windows 10
- IIS 10.0
- .NET Framework 4.8
- 2 GB RAM
- 10 GB disk space

**Recommended:**
- Windows Server 2019/2022
- IIS 10.0+
- .NET Framework 4.8
- 4 GB RAM
- 50 GB disk space (for local storage)

### Database Server Requirements

**SQL Server Express (Free):**
- Up to 10 GB database size
- 1 CPU socket
- 1 GB RAM limit
- Sufficient for small to medium deployments

**SQL Server Standard/Enterprise:**
- Unlimited database size
- Multiple CPUs
- More RAM
- Better for production

**Minimum:**
- 2 GB RAM
- 20 GB disk space
- 1 CPU core

**Recommended:**
- 4-8 GB RAM
- 100 GB+ disk space
- 2+ CPU cores

### Storage Server Requirements

**MinIO:**
- 1 GB RAM minimum
- Disk space depends on file storage needs
- Can run on same server as web app

**AWS S3 / Azure Blob:**
- Cloud-managed
- Pay per storage used
- No server maintenance

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

## Database: SQL Server (MSSQL) - NOT MySQL

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

## Load Balancing (Future)

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

## Summary: Machine Requirements

| Scenario | Machines | Components per Machine |
|----------|----------|------------------------|
| **Development** | 1 | IIS + App + SQL + Storage |
| **Small Production** | 1-2 | Server 1: IIS + App<br>Server 2: SQL (optional) |
| **Production** | 2 | Server 1: IIS + App<br>Server 2: SQL Server |
| **Enterprise** | 3+ | Server 1: IIS + App<br>Server 2: SQL Server<br>Server 3: Storage |
| **Cloud** | 0 (managed) | Azure App Service + Azure SQL + Azure Storage |

**Minimum for Production:** 2 servers  
**Recommended:** 2-3 servers

