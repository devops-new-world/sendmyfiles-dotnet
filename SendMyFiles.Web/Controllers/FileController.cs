using System;
using System.IO;
using System.Web;
using System.Web.Mvc;
using SendMyFiles.Business.Services;

namespace SendMyFiles.Web.Controllers
{
    public class FileController : Controller
    {
        private readonly FileTransferService _fileTransferService;

        public FileController()
        {
            _fileTransferService = new FileTransferService();
        }

        [HttpPost]
        public ActionResult Upload(HttpPostedFileBase file, string senderEmail, string recipientEmail)
        {
            if (file == null || file.ContentLength == 0)
            {
                return Json(new { success = false, message = "Please select a file to upload." });
            }

            if (string.IsNullOrEmpty(senderEmail) || string.IsNullOrEmpty(recipientEmail))
            {
                return Json(new { success = false, message = "Please provide both sender and recipient email addresses." });
            }

            try
            {
                var result = _fileTransferService.UploadFileAsync(
                    file.InputStream,
                    file.FileName,
                    file.ContentType,
                    file.ContentLength,
                    senderEmail,
                    recipientEmail
                ).Result;

                if (result.Success)
                {
                    return Json(new { success = true, message = result.Message });
                }
                else
                {
                    return Json(new { success = false, message = result.Message });
                }
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = $"Error: {ex.Message}" });
            }
        }

        public ActionResult Download(string token)
        {
            if (string.IsNullOrEmpty(token))
            {
                return new HttpStatusCodeResult(400, "Invalid download token");
            }

            try
            {
                var result = _fileTransferService.DownloadFileAsync(token).Result;

                if (!result.Success)
                {
                    return new HttpStatusCodeResult(404, result.Message);
                }

                return File(result.FileStream, result.ContentType, result.FileName);
            }
            catch (Exception ex)
            {
                return new HttpStatusCodeResult(500, $"Error downloading file: {ex.Message}");
            }
        }
    }
}

