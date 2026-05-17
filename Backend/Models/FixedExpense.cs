namespace FinanceHackathonAPI.Models
{
    public class FixedExpense
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        
        // Örn: Personel Maaşları, Dükkan Kirası, Abonelikler vb.
        public string Description { get; set; } = string.Empty;
        
        public decimal Amount { get; set; }
        
        // Bu ödemenin düzenli olarak her ayın veya dönemin hangi tarihinde yapılması gerektiği
        public DateTime DueDate { get; set; }
    }
}
