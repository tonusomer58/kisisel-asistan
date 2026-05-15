using FinanceHackathonAPI.DTOs;
using FinanceHackathonAPI.Services;
using Microsoft.AspNetCore.Mvc;

namespace FinanceHackathonAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FinanceController : ControllerBase
    {
        private readonly IGeminiService _geminiService;

        public FinanceController(IGeminiService geminiService)
        {
            _geminiService = geminiService;
        }

        // 1. BİREYSEL - Harcama Analizi
        [HttpPost("analyze-spending")]
        public async Task<ActionResult<FinanceQueryResponse>> AnalyzeSpending([FromBody] FinanceQueryRequest request)
        {
            if (request == null)
                return Ok(new FinanceQueryResponse { IsSuccess = false, ErrorMessage = "Gelen istek verisi boş olamaz." });

            try
            {
                request.AccountType = "Bireysel";
                var advice = await _geminiService.GetFinancialAdviceAsync(request);
                return Ok(new FinanceQueryResponse { IsSuccess = true, AiAdvice = advice });
            }
            catch (Exception ex)
            {
                return Ok(new FinanceQueryResponse { IsSuccess = false, ErrorMessage = $"Beklenmeyen bir hata oluştu: {ex.Message}" });
            }
        }

        // 2. BİREYSEL - Bütçe Planlayıcı
        [HttpPost("budget-planner")]
        public async Task<ActionResult<FinanceQueryResponse>> BudgetPlanner([FromBody] FinanceQueryRequest request)
        {
            if (request == null)
                return Ok(new FinanceQueryResponse { IsSuccess = false, ErrorMessage = "Gelen istek verisi boş olamaz." });

            try
            {
                request.AccountType = "Bireysel_Hedef";
                var advice = await _geminiService.GetFinancialAdviceAsync(request);
                return Ok(new FinanceQueryResponse { IsSuccess = true, AiAdvice = advice });
            }
            catch (Exception ex)
            {
                return Ok(new FinanceQueryResponse { IsSuccess = false, ErrorMessage = $"Beklenmeyen bir hata oluştu: {ex.Message}" });
            }
        }

        // 3. KOBİ - Nakit Akışı
        [HttpPost("sme-cashflow")]
        public async Task<ActionResult<FinanceQueryResponse>> SmeCashFlow([FromBody] FinanceQueryRequest request)
        {
            if (request == null)
                return Ok(new FinanceQueryResponse { IsSuccess = false, ErrorMessage = "Gelen istek verisi boş olamaz." });

            try
            {
                request.AccountType = "KOBI_NakitAkisi";
                var advice = await _geminiService.GetFinancialAdviceAsync(request);
                return Ok(new FinanceQueryResponse { IsSuccess = true, AiAdvice = advice });
            }
            catch (Exception ex)
            {
                return Ok(new FinanceQueryResponse { IsSuccess = false, ErrorMessage = $"Beklenmeyen bir hata oluştu: {ex.Message}" });
            }
        }

        // 4. KOBİ - Ödeme Riski
        [HttpPost("sme-payment-risk")]
        public async Task<ActionResult<FinanceQueryResponse>> SmePaymentRisk([FromBody] FinanceQueryRequest request)
        {
            if (request == null)
                return Ok(new FinanceQueryResponse { IsSuccess = false, ErrorMessage = "Gelen istek verisi boş olamaz." });

            try
            {
                request.AccountType = "KOBI_Risk";
                var advice = await _geminiService.GetFinancialAdviceAsync(request);
                return Ok(new FinanceQueryResponse { IsSuccess = true, AiAdvice = advice });
            }
            catch (Exception ex)
            {
                return Ok(new FinanceQueryResponse { IsSuccess = false, ErrorMessage = $"Beklenmeyen bir hata oluştu: {ex.Message}" });
            }
        }
    }
}