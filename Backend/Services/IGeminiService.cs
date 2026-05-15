using FinanceHackathonAPI.DTOs;

namespace FinanceHackathonAPI.Services
{
    public interface IGeminiService
    {
        Task<string> GetFinancialAdviceAsync(FinanceQueryRequest request);
    }
}