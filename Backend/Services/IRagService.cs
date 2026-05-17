namespace FinanceHackathonAPI.Services
{
    public interface IRagService
    {
        void AddDocumentToKnowledgeBase(string documentName, string content);
        string GetKnowledgeBaseContext();
    }
}
