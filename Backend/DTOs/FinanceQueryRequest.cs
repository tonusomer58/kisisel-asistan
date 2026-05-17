using FinanceHackathonAPI.Models;

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
        
        // Yeni eklenen detaylı listeler
        public List<Invoice> Invoices { get; set; } = new List<Invoice>();
        public List<Collection> Collections { get; set; } = new List<Collection>();
        public List<Transaction> Transactions { get; set; } = new List<Transaction>();
        public List<FixedExpense> FixedExpenses { get; set; } = new List<FixedExpense>();
        
        // JSON string olarak harcama/fatura detayları (Hackathon için pratik bir yöntem)
        public string TransactionDetails { get; set; } = string.Empty; 
    }
}