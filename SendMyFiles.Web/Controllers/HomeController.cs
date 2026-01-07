using System.Web.Mvc;
using SendMyFiles.Business.Services;
using SendMyFiles.Data.Repositories;
using SendMyFiles.Models;

namespace SendMyFiles.Web.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public ActionResult Index(string senderEmail, string recipientEmail)
        {
            if (string.IsNullOrEmpty(senderEmail) || string.IsNullOrEmpty(recipientEmail))
            {
                ViewBag.Error = "Please provide both sender and recipient email addresses.";
                return View();
            }

            var userRepository = new UserRepository();
            var sender = userRepository.GetOrCreateUser(senderEmail);

            ViewBag.SenderEmail = senderEmail;
            ViewBag.RecipientEmail = recipientEmail;
            ViewBag.UserType = sender.UserType;
            ViewBag.UsedQuota = sender.UsedQuota;
            ViewBag.QuotaLimit = sender.UserType == "Free" ? User.FreeQuotaLimit : long.MaxValue;
            ViewBag.AvailableQuota = sender.UserType == "Free" ? (User.FreeQuotaLimit - sender.UsedQuota) : long.MaxValue;

            return View();
        }
    }
}

