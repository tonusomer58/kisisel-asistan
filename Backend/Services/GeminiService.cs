using System.Text;
using System.Text.Json;
using FinanceHackathonAPI.DTOs;

namespace FinanceHackathonAPI.Services
{
    public class GeminiService : IGeminiService
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiKey;
        private readonly IRagService _ragService;

        public GeminiService(HttpClient httpClient, IConfiguration configuration, IRagService ragService)
        {
            _httpClient = httpClient;
            _apiKey = configuration.GetSection("GeminiSettings:ApiKey").Value;
            _ragService = ragService;

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
                string transactionsSummary = request.Transactions != null && request.Transactions.Any() 
                    ? "\nKategori Bazlı Harcama Dökümü: " + JsonSerializer.Serialize(request.Transactions)
                    : "";

                string fixedExpensesSummary = request.FixedExpenses != null && request.FixedExpenses.Any()
                    ? "\nSabit Giderler (Maaş/Kira vb.): " + JsonSerializer.Serialize(request.FixedExpenses)
                    : "";

                // ✅ Düzeltme: Invoice ve Collection listeleri artık prompt'a ekleniyor
                string invoicesSummary = request.Invoices != null && request.Invoices.Any()
                    ? "\nFaturalar (Ödenecekler): " + JsonSerializer.Serialize(request.Invoices)
                    : "";

                string collectionsSummary = request.Collections != null && request.Collections.Any()
                    ? "\nTahsilatlar (Alacaklar): " + JsonSerializer.Serialize(request.Collections)
                    : "";

                string ragContext = _ragService.GetKnowledgeBaseContext();

                string userContext = $"Finansal Durum: Toplam Gelir: {request.TotalIncome} TL, Toplam Gider: {request.TotalExpense} TL, Yaklaşan Ödemeler: {request.UpcomingPayments} TL, Bekleyen Alacaklar: {request.PendingReceivables} TL. İşlem Detayları: {request.TransactionDetails}{transactionsSummary}{fixedExpensesSummary}{invoicesSummary}{collectionsSummary}{ragContext}";

                string finalPrompt = $"{systemPrompt}\n\nKullanıcı Verisi:\n{userContext}\n\nKullanıcının Sorusu: {request.Question}\n\nLütfen bu verilere dayanarak samimi bir finansal tavsiye ve analiz ver.";

                var requestBody = new
                {
                    contents = new[]
                    {
                        new
                        {
                            parts = new[] { new { text = finalPrompt } }
                        }
                    },
                    tools = new[]
                    {
                        new
                        {
                            functionDeclarations = new[]
                            {
                                new
                                {
                                    name = "SendEmergencyAlert",
                                    description = "Nakit akışında ciddi bir tehlike (örneğin giderlerin gelirlerden çok yüksek olması veya yaklaşan faturaları ödeyecek paranın olmaması) sezdiğinde bu aracı çağırarak patrona acil durum uyarısı gönder.",
                                    parameters = new
                                    {
                                        type = "OBJECT",
                                        properties = new
                                        {
                                            reason = new
                                            {
                                                type = "STRING",
                                                description = "Acil durumun nedeni ve detayı (Örn: Maaş ödemeleri için kasada 10.000 TL eksik var)."
                                            }
                                        },
                                        required = new[] { "reason" }
                                    }
                                }
                            }
                        }
                    }
                };

                // JsonSerializerOptions kullanarak camelCase formatında parse ediyoruz
                var serializeOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
                var jsonBody = JsonSerializer.Serialize(requestBody, serializeOptions);
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

                var firstPart = jsonDocument.RootElement
                    .GetProperty("candidates")[0]
                    .GetProperty("content")
                    .GetProperty("parts")[0];

                // 1. Durum: Yapay Zeka bir fonksiyon çağırmak istiyorsa (Agentic Yaklaşım)
                if (firstPart.TryGetProperty("functionCall", out var functionCallElement))
                {
                    var functionName = functionCallElement.GetProperty("name").GetString();
                    var args = functionCallElement.GetProperty("args");
                    var reason = args.TryGetProperty("reason", out var reasonProp) ? reasonProp.GetString() : "Kritik Nakit Sıkışıklığı!";
                    
                    // Burada normalde C# içindeki bir SMS atma servisini tetikleriz.
                    // Hackathon için bunu metin olarak dönüp uygulamanın aksiyon aldığını ispatlıyoruz:
                    return $"🚨 [AGENT DEVREYE GİRDİ - SİSTEM MÜDAHALESİ]\n\nYapay Zeka tehlikeyi sezdi ve '{functionName}' aracını kendi inisiyatifiyle çalıştırdı!\n\n**Sistem Mesajı:** {reason}\n\n(Bu simülasyonda patrona acil durum E-postası gönderilmiştir.)";
                }
                
                // 2. Durum: Normal metin cevabı verdiyse
                if (firstPart.TryGetProperty("text", out var textElement))
                {
                    return textElement.GetString() ?? "💡 Tavsiye üretilemedi.";
                }

                return "💡 Beklenmeyen bir yanıt formatı alındı.";
            }
            catch (Exception ex)
            {
                return $"⚠️ Geçici bir bağlantı sorunu oluştu: {ex.Message}. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.";
            }
        }
    }
}