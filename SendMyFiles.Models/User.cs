using System;
using System.ComponentModel.DataAnnotations;

namespace SendMyFiles.Models
{
    public class User
    {
        public int UserId { get; set; }

        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        public string UserType { get; set; } // "Free" or "Premium"

        public DateTime CreatedDate { get; set; }

        public long UsedQuota { get; set; } // in bytes

        public const long FreeQuotaLimit = 50 * 1024 * 1024; // 50 MB in bytes
    }
}

