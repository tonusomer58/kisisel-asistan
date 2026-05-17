using System.Net;
using System.Net.Mail;

namespace FinanceHackathonAPI.Services
{
    public interface IEmailService
    {
        Task SendEmailAsync(string toEmail, string subject, string message);
    }

    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;

        public EmailService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public async Task SendEmailAsync(string toEmail, string subject, string message)
        {
            var smtpHost = _configuration["EmailSettings:SmtpHost"];
            var smtpPort = int.Parse(_configuration["EmailSettings:SmtpPort"] ?? "587");
            var smtpUser = _configuration["EmailSettings:SmtpUser"];
            var smtpPass = _configuration["EmailSettings:SmtpPass"];

            if (string.IsNullOrEmpty(smtpUser) || string.IsNullOrEmpty(smtpPass))
            {
                Console.WriteLine("Uyarı: E-Posta atılamadı çünkü appsettings.json içinde SMTP bilgileri eksik!");
                return;
            }

            using var client = new SmtpClient(smtpHost, smtpPort)
            {
                Credentials = new NetworkCredential(smtpUser, smtpPass),
                EnableSsl = true
            };

            var mailMessage = new MailMessage
            {
                From = new MailAddress(smtpUser, "KOBİ Finans Asistanı"),
                Subject = subject,
                Body = message,
                IsBodyHtml = true
            };
            
            mailMessage.To.Add(toEmail);

            try
            {
                await client.SendMailAsync(mailMessage);
                Console.WriteLine($"Başarılı: {toEmail} adresine hatırlatma maili fırlatıldı!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Hata: Mail gönderilirken bir sorun oluştu: {ex.Message}");
            }
        }
    }
}
