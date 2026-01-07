using System;
using System.Configuration;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;

namespace SendMyFiles.Business.Services
{
    public class EmailService
    {
        private readonly string _smtpServer;
        private readonly int _smtpPort;
        private readonly string _smtpUsername;
        private readonly string _smtpPassword;
        private readonly bool _enableSSL;
        private readonly string _fromEmail;

        public EmailService()
        {
            _smtpServer = ConfigurationManager.AppSettings["SmtpServer"] ?? "smtp.gmail.com";
            _smtpPort = int.Parse(ConfigurationManager.AppSettings["SmtpPort"] ?? "587");
            _smtpUsername = ConfigurationManager.AppSettings["SmtpUsername"] ?? "";
            _smtpPassword = ConfigurationManager.AppSettings["SmtpPassword"] ?? "";
            _enableSSL = bool.Parse(ConfigurationManager.AppSettings["SmtpEnableSSL"] ?? "true");
            _fromEmail = ConfigurationManager.AppSettings["SmtpFromEmail"] ?? _smtpUsername;
        }

        public async Task SendFileNotificationAsync(string recipientEmail, string senderEmail, string fileName, string downloadLink)
        {
            try
            {
                using (var client = new SmtpClient(_smtpServer, _smtpPort))
                {
                    client.EnableSsl = _enableSSL;
                    client.Credentials = new NetworkCredential(_smtpUsername, _smtpPassword);

                    var message = new MailMessage(_fromEmail, recipientEmail)
                    {
                        Subject = "You have a new file to receive",
                        Body = $@"
Hello,

You have received a new file from {senderEmail}.

File Name: {fileName}

Click the link below to download your file:
{downloadLink}

This link will expire in 7 days.

Best regards,
SendMyFiles Team
",
                        IsBodyHtml = false
                    };

                    await client.SendMailAsync(message);
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"Error sending email: {ex.Message}", ex);
            }
        }
    }
}

