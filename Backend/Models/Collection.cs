namespace FinanceHackathonAPI.Models
{
    public class Collection
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Description { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public DateTime ExpectedDate { get; set; }
        public bool IsCollected { get; set; }
    }
}
