# Dockerfile for SendMyFiles Web Application
# This requires Windows containers (Windows Server Core base image)
# 
# Build steps:
# 1. Publish the application first (or use multi-stage build)
# 2. Build image: docker build -t sendmyfiles-webapp .
# 3. Or use docker-compose which will handle the build

FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2022

# Set working directory
WORKDIR /inetpub/wwwroot

# Copy application files
# Note: For production, you should publish the app first and copy published files
# For development, we copy source files (IIS will compile on first request)
COPY SendMyFiles.Web/ /inetpub/wwwroot/
COPY SendMyFiles.Business/bin/ /inetpub/wwwroot/bin/
COPY SendMyFiles.Data/bin/ /inetpub/wwwroot/bin/
COPY SendMyFiles.Models/bin/ /inetpub/wwwroot/bin/

# Copy NuGet packages if needed
# COPY packages/ /inetpub/wwwroot/bin/

# Create App_Data directory for local storage (if not using MinIO)
RUN powershell -Command \
    New-Item -ItemType Directory -Force -Path C:\inetpub\wwwroot\App_Data\Uploads | Out-Null; \
    New-Item -ItemType Directory -Force -Path C:\inetpub\wwwroot\bin | Out-Null

# Set permissions for App_Data
RUN icacls "C:\inetpub\wwwroot\App_Data" /grant "IIS_IUSRS:(OI)(CI)F" /T

# Expose port 80
EXPOSE 80

# The base image already has IIS configured, so the application will be served automatically
# IIS will compile the application on first request if needed

