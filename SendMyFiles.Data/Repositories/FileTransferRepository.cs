using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using SendMyFiles.Models;

namespace SendMyFiles.Data.Repositories
{
    public class FileTransferRepository
    {
        public int CreateFileTransfer(FileTransfer fileTransfer)
        {
            using (var context = new DatabaseContext())
            {
                string query = @"INSERT INTO FileTransfers 
                    (FileName, FilePath, FileSize, ContentType, SenderEmail, RecipientEmail, UploadDate, IsDownloaded, AccessToken, ExpiryDate)
                    OUTPUT INSERTED.FileTransferId
                    VALUES (@FileName, @FilePath, @FileSize, @ContentType, @SenderEmail, @RecipientEmail, @UploadDate, @IsDownloaded, @AccessToken, @ExpiryDate)";

                using (var cmd = new SqlCommand(query, context.Connection))
                {
                    cmd.Parameters.AddWithValue("@FileName", fileTransfer.FileName);
                    cmd.Parameters.AddWithValue("@FilePath", fileTransfer.FilePath);
                    cmd.Parameters.AddWithValue("@FileSize", fileTransfer.FileSize);
                    cmd.Parameters.AddWithValue("@ContentType", fileTransfer.ContentType);
                    cmd.Parameters.AddWithValue("@SenderEmail", fileTransfer.SenderEmail);
                    cmd.Parameters.AddWithValue("@RecipientEmail", fileTransfer.RecipientEmail);
                    cmd.Parameters.AddWithValue("@UploadDate", fileTransfer.UploadDate);
                    cmd.Parameters.AddWithValue("@IsDownloaded", fileTransfer.IsDownloaded);
                    cmd.Parameters.AddWithValue("@AccessToken", fileTransfer.AccessToken);
                    cmd.Parameters.AddWithValue("@ExpiryDate", fileTransfer.ExpiryDate);

                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public FileTransfer GetFileTransferByToken(string accessToken)
        {
            using (var context = new DatabaseContext())
            {
                string query = @"SELECT FileTransferId, FileName, FilePath, FileSize, ContentType, SenderEmail, RecipientEmail, 
                    UploadDate, DownloadDate, IsDownloaded, AccessToken, ExpiryDate
                    FROM FileTransfers WHERE AccessToken = @AccessToken";

                using (var cmd = new SqlCommand(query, context.Connection))
                {
                    cmd.Parameters.AddWithValue("@AccessToken", accessToken);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return new FileTransfer
                            {
                                FileTransferId = reader.GetInt32(0),
                                FileName = reader.GetString(1),
                                FilePath = reader.GetString(2),
                                FileSize = reader.GetInt64(3),
                                ContentType = reader.GetString(4),
                                SenderEmail = reader.GetString(5),
                                RecipientEmail = reader.GetString(6),
                                UploadDate = reader.GetDateTime(7),
                                DownloadDate = reader.IsDBNull(8) ? (DateTime?)null : reader.GetDateTime(8),
                                IsDownloaded = reader.GetBoolean(9),
                                AccessToken = reader.GetString(10),
                                ExpiryDate = reader.GetDateTime(11)
                            };
                        }
                    }
                }
            }
            return null;
        }

        public void MarkAsDownloaded(int fileTransferId)
        {
            using (var context = new DatabaseContext())
            {
                string query = "UPDATE FileTransfers SET IsDownloaded = 1, DownloadDate = @DownloadDate WHERE FileTransferId = @FileTransferId";
                using (var cmd = new SqlCommand(query, context.Connection))
                {
                    cmd.Parameters.AddWithValue("@FileTransferId", fileTransferId);
                    cmd.Parameters.AddWithValue("@DownloadDate", DateTime.Now);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public List<FileTransfer> GetFilesByRecipientEmail(string email)
        {
            var files = new List<FileTransfer>();
            using (var context = new DatabaseContext())
            {
                string query = @"SELECT FileTransferId, FileName, FilePath, FileSize, ContentType, SenderEmail, RecipientEmail, 
                    UploadDate, DownloadDate, IsDownloaded, AccessToken, ExpiryDate
                    FROM FileTransfers WHERE RecipientEmail = @Email ORDER BY UploadDate DESC";

                using (var cmd = new SqlCommand(query, context.Connection))
                {
                    cmd.Parameters.AddWithValue("@Email", email);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            files.Add(new FileTransfer
                            {
                                FileTransferId = reader.GetInt32(0),
                                FileName = reader.GetString(1),
                                FilePath = reader.GetString(2),
                                FileSize = reader.GetInt64(3),
                                ContentType = reader.GetString(4),
                                SenderEmail = reader.GetString(5),
                                RecipientEmail = reader.GetString(6),
                                UploadDate = reader.GetDateTime(7),
                                DownloadDate = reader.IsDBNull(8) ? (DateTime?)null : reader.GetDateTime(8),
                                IsDownloaded = reader.GetBoolean(9),
                                AccessToken = reader.GetString(10),
                                ExpiryDate = reader.GetDateTime(11)
                            });
                        }
                    }
                }
            }
            return files;
        }
    }
}

