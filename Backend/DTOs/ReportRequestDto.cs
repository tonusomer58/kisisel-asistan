using FinanceHackathonAPI.Models;

namespace FinanceHackathonAPI.DTOs
{
    /// <summary>
    /// "Aylık Finansal Röntgen" PDF raporu oluşturmak için gelen istek modeli.
    /// </summary>
    public class ReportRequestDto
    {
        // Rapor başlığında görünecek kişi/şirket adı
        public string OwnerName { get; set; } = "Kullanıcı";

        // Raporun kapsadığı dönem (Örn: "Mayıs 2026")
        public string ReportPeriod { get; set; } = DateTime.Now.ToString("MMMM yyyy");

        // Hesap tipi: "Bireysel" veya "KOBI"
        public string AccountType { get; set; } = "Bireysel";

        // Finansal özet rakamları
        public decimal TotalIncome { get; set; }
        public decimal TotalExpense { get; set; }
        public decimal PendingReceivables { get; set; }
        public decimal UpcomingPayments { get; set; }

        // Detaylı listeler (opsiyonel)
        public List<Transaction> Transactions { get; set; } = new();
        public List<FixedExpense> FixedExpenses { get; set; } = new();
        public List<Invoice> Invoices { get; set; } = new();
        public List<Collection> Collections { get; set; } = new();

        // Gemini'nin ürettiği aksiyon planı (frontend önce analyze-spending vb.'yi çağırır,
        // dönen AiAdvice'ı buraya koyar)
        public string AiActionPlan { get; set; } = string.Empty;
    }
}
