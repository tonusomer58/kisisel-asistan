using System.Text;

namespace FinanceHackathonAPI.Services
{
    public class RagService : IRagService
    {
        // Hackathon için geçici In-Memory RAG / Vektör Veritabanı simülasyonu
        private readonly List<string> _knowledgeBase = new List<string>();

        public void AddDocumentToKnowledgeBase(string documentName, string content)
        {
            // Gerçek bir senaryoda burada PDF okunur, chunk'lara (parçalara) bölünür
            // ve Pinecone/Qdrant gibi bir vektör veritabanına embedding (vektör) olarak kaydedilir.
            
            _knowledgeBase.Add($"--- {documentName} İÇERİĞİ ---\n{content}");
        }

        public string GetKnowledgeBaseContext()
        {
            if (!_knowledgeBase.Any())
                return string.Empty;

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("\n\n[SİSTEM BİLGİSİ - RAG (Retrieval-Augmented Generation) VERİ TABANI]:");
            sb.AppendLine("Aşağıdaki bilgiler kullanıcının sisteme önceden yüklediği geçmiş raporlardan elde edilmiştir. Kullanıcıya analiz verirken mutlaka bu RAG verilerini de hesaba katarak (geçmişle kıyaslayarak) cevap ver:");
            
            foreach (var doc in _knowledgeBase)
            {
                sb.AppendLine(doc);
            }

            return sb.ToString();
        }
    }
}
