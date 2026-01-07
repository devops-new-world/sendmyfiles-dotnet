using System;
using System.IO;
using System.Threading.Tasks;
using SendMyFiles.Data.Repositories;
using SendMyFiles.Models;

namespace SendMyFiles.Business.Services
{
    public class FileTransferService
    {
        private readonly FileTransferRepository _fileTransferRepository;
        private readonly UserRepository _userRepository;
        private readonly FileStorageService _fileStorageService;
        private readonly EmailService _emailService;

        public FileTransferService()
        {
            _fileTransferRepository = new FileTransferRepository();
            _userRepository = new UserRepository();
            _fileStorageService = new FileStorageService();
            _emailService = new EmailService();
        }

        public async Task<FileTransferResult> UploadFileAsync(Stream fileStream, string fileName, string contentType, long fileSize, string senderEmail, string recipientEmail)
        {
            // Get or create sender user
            var sender = _userRepository.GetOrCreateUser(senderEmail);

            // Check quota for free users
            if (sender.UserType == "Free")
            {
                long newQuota = sender.UsedQuota + fileSize;
                if (newQuota > User.FreeQuotaLimit)
                {
                    return new FileTransferResult
                    {
                        Success = false,
                        Message = $"File size exceeds your available quota. You have {FormatBytes(User.FreeQuotaLimit - sender.UsedQuota)} remaining out of {FormatBytes(User.FreeQuotaLimit)}."
                    };
                }
            }

            try
            {
                // Upload file to storage
                string filePath = await _fileStorageService.UploadFileAsync(fileStream, fileName, contentType);

                // Generate access token
                string accessToken = Guid.NewGuid().ToString("N");

                // Create file transfer record
                var fileTransfer = new FileTransfer
                {
                    FileName = fileName,
                    FilePath = filePath,
                    FileSize = fileSize,
                    ContentType = contentType,
                    SenderEmail = senderEmail,
                    RecipientEmail = recipientEmail,
                    UploadDate = DateTime.Now,
                    IsDownloaded = false,
                    AccessToken = accessToken,
                    ExpiryDate = DateTime.Now.AddDays(7)
                };

                int fileTransferId = _fileTransferRepository.CreateFileTransfer(fileTransfer);

                // Update user quota
                _userRepository.UpdateUserQuota(sender.UserId, fileSize);

                // Send email notification
                string baseUrl = System.Configuration.ConfigurationManager.AppSettings["BaseUrl"] ?? "http://localhost:8080";
                string downloadLink = $"{baseUrl}/File/Download?token={accessToken}";

                await _emailService.SendFileNotificationAsync(recipientEmail, senderEmail, fileName, downloadLink);

                return new FileTransferResult
                {
                    Success = true,
                    Message = "File uploaded successfully and recipient has been notified.",
                    FileTransferId = fileTransferId,
                    AccessToken = accessToken
                };
            }
            catch (Exception ex)
            {
                return new FileTransferResult
                {
                    Success = false,
                    Message = $"Error uploading file: {ex.Message}"
                };
            }
        }

        public async Task<FileDownloadResult> DownloadFileAsync(string accessToken)
        {
            var fileTransfer = _fileTransferRepository.GetFileTransferByToken(accessToken);

            if (fileTransfer == null)
            {
                return new FileDownloadResult
                {
                    Success = false,
                    Message = "File not found or invalid access token."
                };
            }

            if (fileTransfer.ExpiryDate < DateTime.Now)
            {
                return new FileDownloadResult
                {
                    Success = false,
                    Message = "This file link has expired."
                };
            }

            try
            {
                var fileStream = await _fileStorageService.DownloadFileAsync(fileTransfer.FilePath);

                // Mark as downloaded if not already
                if (!fileTransfer.IsDownloaded)
                {
                    _fileTransferRepository.MarkAsDownloaded(fileTransfer.FileTransferId);
                }

                return new FileDownloadResult
                {
                    Success = true,
                    FileStream = fileStream,
                    FileName = fileTransfer.FileName,
                    ContentType = fileTransfer.ContentType
                };
            }
            catch (Exception ex)
            {
                return new FileDownloadResult
                {
                    Success = false,
                    Message = $"Error downloading file: {ex.Message}"
                };
            }
        }

        private string FormatBytes(long bytes)
        {
            string[] sizes = { "B", "KB", "MB", "GB" };
            double len = bytes;
            int order = 0;
            while (len >= 1024 && order < sizes.Length - 1)
            {
                order++;
                len = len / 1024;
            }
            return $"{len:0.##} {sizes[order]}";
        }
    }

    public class FileTransferResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public int FileTransferId { get; set; }
        public string AccessToken { get; set; }
    }

    public class FileDownloadResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public Stream FileStream { get; set; }
        public string FileName { get; set; }
        public string ContentType { get; set; }
    }
}

