namespace FinanceHackathonAPI.Services
{
    public class PaymentReminderService : BackgroundService
    {
        private readonly ILogger<PaymentReminderService> _logger;

        public PaymentReminderService(ILogger<PaymentReminderService> logger)
        {
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Ödeme Hatırlatıcı Arka Plan Servisi Başladı.");

            while (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Yaklaşan ödemeler ve geciken tahsilatlar kontrol ediliyor... Zaman: {time}", DateTimeOffset.Now);

                // TODO: Gerçek bir senaryoda burada veritabanına bağlanıp ödemesi yaklaşan "Invoice" 
                // veya "Collection" kayıtları çekilerek e-posta/SMS gönderimi tetiklenir.
                
                // Örnek:
                // var yaklasanFaturalar = _dbContext.Invoices.Where(i => !i.IsPaid && i.DueDate <= DateTime.Now.AddDays(3)).ToList();
                // foreach(var fatura in yaklasanFaturalar) { 
                //     _notificationService.SendEmail("Ödemeniz Yaklaşıyor: " + fatura.Description);
                // }

                // Test / Hackathon gösterimi için 1 dakikada bir çalışacak şekilde ayarlandı. 
                // Canlıda günde 1 kez çalışması için TimeSpan.FromDays(1) yapılmalıdır.
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }
    }
}
