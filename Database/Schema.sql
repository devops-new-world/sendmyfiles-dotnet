-- SendMyFiles Database Schema
-- Run this script to create the database and tables

-- Create Database (if not exists)
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SendMyFiles')
BEGIN
    CREATE DATABASE SendMyFiles;
END
GO

USE SendMyFiles;
GO

-- Create Users Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Users] (
        [UserId] INT IDENTITY(1,1) PRIMARY KEY,
        [Email] NVARCHAR(255) NOT NULL UNIQUE,
        [UserType] NVARCHAR(50) NOT NULL DEFAULT 'Free',
        [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
        [UsedQuota] BIGINT NOT NULL DEFAULT 0
    );
    
    CREATE INDEX IX_Users_Email ON [dbo].[Users]([Email]);
END
GO

-- Create FileTransfers Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FileTransfers]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FileTransfers] (
        [FileTransferId] INT IDENTITY(1,1) PRIMARY KEY,
        [FileName] NVARCHAR(500) NOT NULL,
        [FilePath] NVARCHAR(1000) NOT NULL,
        [FileSize] BIGINT NOT NULL,
        [ContentType] NVARCHAR(255) NOT NULL,
        [SenderEmail] NVARCHAR(255) NOT NULL,
        [RecipientEmail] NVARCHAR(255) NOT NULL,
        [UploadDate] DATETIME NOT NULL DEFAULT GETDATE(),
        [DownloadDate] DATETIME NULL,
        [IsDownloaded] BIT NOT NULL DEFAULT 0,
        [AccessToken] NVARCHAR(255) NOT NULL UNIQUE,
        [ExpiryDate] DATETIME NOT NULL
    );
    
    CREATE INDEX IX_FileTransfers_AccessToken ON [dbo].[FileTransfers]([AccessToken]);
    CREATE INDEX IX_FileTransfers_RecipientEmail ON [dbo].[FileTransfers]([RecipientEmail]);
    CREATE INDEX IX_FileTransfers_SenderEmail ON [dbo].[FileTransfers]([SenderEmail]);
END
GO

