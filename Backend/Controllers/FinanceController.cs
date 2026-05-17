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
        private readonly IRagService _ragService;
        private readonly IEmailService _emailService;

        public FinanceController(IGeminiService geminiService, IRagService ragService, IEmailService emailService)
        {
            _geminiService = geminiService;
            _ragService = ragService;
            _emailService = emailService;
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

        // 5. RAG - Belge Yükleme Endpoint'i (Kullanıcının geçmiş raporlarını AI'a okutması için)
        [HttpPost("upload-report")]
        public async Task<IActionResult> UploadReport(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Lütfen geçerli bir dosya yükleyin (.txt formatında bilanço vb.).");

            try
            {
                using var reader = new StreamReader(file.OpenReadStream());
                var content = await reader.ReadToEndAsync();
                
                _ragService.AddDocumentToKnowledgeBase(file.FileName, content);

                return Ok(new { IsSuccess = true, Message = $"{file.FileName} başarıyla RAG Vektör Veritabanına işlendi! Artık Gemini bu rapora göre de cevap verebilir." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Dosya işlenirken hata oluştu: {ex.Message}");
            }
        }

        // 6. Hemen Şimdi Mail Gönderme (Anında Çalışır)
        [HttpPost("send-email")]
        public async Task<IActionResult> SendEmailNow([FromBody] FinanceHackathonAPI.Models.ReminderRequest request)
        {
            if (request == null || string.IsNullOrEmpty(request.Email))
                return BadRequest("Geçerli bir mail bilgisi girin.");

            try
            {
                await _emailService.SendEmailAsync(request.Email, request.Subject, request.Message);
                return Ok(new { IsSuccess = true, Message = $"{request.Email} adresine e-posta başarıyla gönderildi!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Mail gönderilirken hata oluştu: {ex.Message}");
            }
        }

        // 7. Hangfire ile İleri Tarihli Hatırlatıcı (Email) Kurma
        [HttpPost("schedule-reminder")]
        public IActionResult ScheduleReminder([FromBody] FinanceHackathonAPI.Models.ReminderRequest request)
        {
            if (request == null || string.IsNullOrEmpty(request.Email))
                return BadRequest("Geçerli bir hatırlatıcı bilgisi (e-posta vb.) girin.");

            // İleri bir tarihe iş planlamak için hedeflenen zamanı alıyoruz.
            var delay = request.ScheduledTime - DateTime.UtcNow;
            
            if (delay.TotalSeconds <= 0)
                return BadRequest("Geçmiş bir zamana hatırlatıcı kurulamaz. Lütfen gelecekteki bir tarihi seçin.");

            // Hangfire'a görevi veriyoruz, zamanı geldiğinde EmailService'i tetikleyecek.
            Hangfire.BackgroundJob.Schedule<IEmailService>(
                emailService => emailService.SendEmailAsync(request.Email, request.Subject, request.Message),
                delay
            );

            return Ok(new { IsSuccess = true, Message = $"{request.ScheduledTime} tarihi için hatırlatıcı başarıyla Hangfire kuyruğuna alındı. Zamanı gelince {request.Email} adresine e-posta atılacak." });
        }
    }
}