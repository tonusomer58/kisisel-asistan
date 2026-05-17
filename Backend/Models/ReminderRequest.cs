namespace FinanceHackathonAPI.Models
{
    public class ReminderRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Subject { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        
        // Hatırlatıcının tetikleneceği ileri tarih (UTC olarak gelmesi önerilir)
        public DateTime ScheduledTime { get; set; }
    }
}
