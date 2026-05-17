namespace FinanceHackathonAPI.Models
{
    public class Transaction
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Description { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        
        // Örn: Market, Ulaşım, Eğlence, Fatura, Eğitim vb.
        public string Category { get; set; } = string.Empty; 
        
        public DateTime Date { get; set; }
    }
}
