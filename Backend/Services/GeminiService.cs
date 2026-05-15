using System.Text;
using System.Text.Json;
using FinanceHackathonAPI.DTOs;

namespace FinanceHackathonAPI.Services
{
    public class GeminiService : IGeminiService
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiKey;

        public GeminiService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _apiKey = configuration.GetSection("GeminiSettings:ApiKey").Value;

            if (string.IsNullOrEmpty(_apiKey))
                throw new ArgumentNullException("API Key appsettings.json dosyasında boş!");
        }

        public async Task<string> GetFinancialAdviceAsync(FinanceQueryRequest request)
        {
            if (request == null)
                return "💡 Gelen veri boş. Lütfen geçerli finansal veriler gönderin.";

            try
            {
                string systemPrompt = request.AccountType != null && request.AccountType.StartsWith("KOBI")
                    ? "Sen bir finans dehasısın ve şirketlerin nakit akışını, faturalarını analiz eden çok samimi bir uzmansın! 🚀 Yanıtlarında mutlaka bolca emoji kullan, sıcak ve destekleyici bir dil benimse. Şirketin maliyetlerini düşürmesi veya gelirini artırması için pratik, uygulanabilir bir 'gizli ipucu' vermeyi asla unutma. 💡"
                    : "Sen bir finans dehasısın ve kişisel bütçe optimizasyonu konusunda harikalar yaratan çok samimi bir asistansın! 💸 Yanıtlarında mutlaka bolca emoji kullan, motive edici ve dostane bir dil benimse. Kullanıcının daha fazla tasarruf yapabilmesi için her defasında zekice bir 'gizli ipucu' vermeyi asla unutma. 💡";

                string userContext = $"Finansal Durum: Toplam Gelir: {request.TotalIncome} TL, Toplam Gider: {request.TotalExpense} TL, Yaklaşan Ödemeler: {request.UpcomingPayments} TL, Bekleyen Alacaklar: {request.PendingReceivables} TL. İşlem Detayları: {request.TransactionDetails}";

                string finalPrompt = $"{systemPrompt}\n\nKullanıcı Verisi:\n{userContext}\n\nKullanıcının Sorusu: {request.Question}\n\nLütfen bu verilere dayanarak samimi bir finansal tavsiye ve analiz ver.";

                var requestBody = new
                {
                    contents = new[]
                    {
                        new
                        {
                            parts = new[] { new { text = finalPrompt } }
                        }
                    }
                };

                var jsonBody = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(jsonBody, Encoding.UTF8, "application/json");

                // Tek API key ile v1beta üzerinden 2.5-flash modeline istek atıyoruz
                string url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={_apiKey}";

                var response = await _httpClient.PostAsync(url, content);

                if (!response.IsSuccessStatusCode)
                {
                    var error = await response.Content.ReadAsStringAsync();
                    return $"⚠️ Yapay zeka servisine erişilemedi. Lütfen daha sonra tekrar deneyin. (Detay: {response.StatusCode})";
                }

                var responseString = await response.Content.ReadAsStringAsync();
                using var jsonDocument = JsonDocument.Parse(responseString);

                var aiText = jsonDocument.RootElement
                    .GetProperty("candidates")[0]
                    .GetProperty("content")
                    .GetProperty("parts")[0]
                    .GetProperty("text")
                    .GetString();

                return aiText ?? "💡 Tavsiye üretilemedi, ancak finansal durumunuz güvende!";
            }
            catch (Exception ex)
            {
                return $"⚠️ Geçici bir bağlantı sorunu oluştu: {ex.Message}. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.";
            }
        }
    }
}