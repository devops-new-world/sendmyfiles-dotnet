using System;
using System.ComponentModel.DataAnnotations;

namespace SendMyFiles.Models
{
    public class FileTransfer
    {
        public int FileTransferId { get; set; }

        [Required]
        public string FileName { get; set; }

        [Required]
        public string FilePath { get; set; } // Path in MinIO/S3

        [Required]
        public long FileSize { get; set; } // in bytes

        [Required]
        public string ContentType { get; set; }

        [Required]
        [EmailAddress]
        public string SenderEmail { get; set; }

        [Required]
        [EmailAddress]
        public string RecipientEmail { get; set; }

        public DateTime UploadDate { get; set; }

        public DateTime? DownloadDate { get; set; }

        public bool IsDownloaded { get; set; }

        public string AccessToken { get; set; } // Unique token for download link

        public DateTime ExpiryDate { get; set; }
    }
}

