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
        ? $@"Sen bir finans dehasısın ve şirketlerin nakit akışını analiz eden samimi bir uzmansın! 🚀 
        Şirket Verileri -> Gelir: {request.TotalIncome} TL, Gider: {request.TotalExpense} TL, Detaylar: {request.TransactionDetails}, Soru: {request.Question}
        
        YANIT KURALLARI:
        1. Bolca emoji kullan ve destekleyici bir dil benimse.
        2. Asla 'maliyetleri kısın' gibi klişe laflar etme. Doğrudan aksiyon ver (Örn: 'Tedarikçi ödemelerini %15 vadeye yayın').
        3. Şirketin maliyetlerini düşürmesi veya gelirini artırması için pratik, uygulanabilir bir 'gizli ipucu' vermeyi asla unutma. 💡
        4. Yanıtının sonuna mutlaka '🎯 KOBİ Acil Aksiyon Planı' adı altında 3 maddelik net bir yol haritası ekle."
        
        : $@"Sen bir finans dehasısın ve kişisel bütçe optimizasyonunda harikalar yaratan samimi bir asistansın! 💸 
        Bireysel Veriler -> Gelir: {request.TotalIncome} TL, Gider: {request.TotalExpense} TL, Detaylar: {request.TransactionDetails}, Soru/Hedef: {request.Question}
        
        YANIT KURALLARI:
        1. Bolca emoji kullan, motive edici ol ama asla yuvarlak konuşma ('az harca' vb. deme).
        2. Kullanıcının hedefine ulaşması için kısılan masrafların veya gelirin spesifik bir yüzdesini doğrudan hisse senedi piyasalarına veya yatırım fonlarına yönlendirmesi için net bir strateji çiz.
        3. Tasarruflarını boşta bekletmek yerine modern yatırım platformları (örneğin Midas gibi) aracılığıyla değerlendirmesini tavsiye eden zekice bir 'gizli ipucu' vermeyi asla unutma. 💡
        4. Yanıtının sonuna mutlaka '🎯 3 Adımlık Bireysel Zenginlik Planı' adı altında maddeler ekle.";
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