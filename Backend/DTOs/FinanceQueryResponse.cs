namespace FinanceHackathonAPI.DTOs
{
    public class FinanceQueryResponse
    {
        public bool IsSuccess { get; set; }
        public string AiAdvice { get; set; } = string.Empty;
        public string ErrorMessage { get; set; } = string.Empty;
    }
}