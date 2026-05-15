namespace FinanceHackathonAPI.DTOs
{
    public class FinanceQueryRequest
    {
        // "Bireysel" veya "KOBI"
        public string AccountType { get; set; } = string.Empty; 
        
        // Kullanıcının sorduğu soru (Örn: "Neden bu ay fazla harcadım?")
        public string Question { get; set; } = string.Empty;

        // Anlık Finansal Veriler (Frontend bu verileri veritabanından çekip veya statik olarak gönderebilir)
        public decimal TotalIncome { get; set; }
        public decimal TotalExpense { get; set; }
        public decimal PendingReceivables { get; set; } // KOBİ için geciken alacaklar
        public decimal UpcomingPayments { get; set; } // Yaklaşan ödemeler
        
        // JSON string olarak harcama/fatura detayları (Hackathon için pratik bir yöntem)
        public string TransactionDetails { get; set; } = string.Empty; 
    }
}