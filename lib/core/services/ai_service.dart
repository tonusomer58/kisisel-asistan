import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';

class GeminiService {
  static String get _apiKey {
    final String gizlenmisSifre = 'QUl6YVN5Q29SZFVweHR1eWdGWGc0ZXdEZWwzVnlYcHlwRWVVWktv';
    final String apiKey = utf8.decode(base64.decode(gizlenmisSifre));
    return apiKey;
  }
  late final GenerativeModel _model;

  GeminiService() {
    final addTransactionTool = FunctionDeclaration(
      'add_transaction',
      'Gelir veya gider işlemi ekler. Kullanıcı bir harcama veya gelir bildirdiğinde bu fonksiyonu çağır.',
      Schema.object(
        properties: {
          'title': Schema.string(description: 'İşlem başlığı (örn: Maaş, Market, Kira)'),
          'amount': Schema.number(description: 'İşlem tutarı (Sayısal değer)'),
          'type': Schema.string(description: 'İşlem tipi: "income" (gelir) veya "expense" (gider)'),
          'category': Schema.string(description: 'Gider kategorisi (Market, Fatura, Eğitim, Eğlence, Sağlık, Diğer).'),
        },
        requiredProperties: ['title', 'amount', 'type'],
      ),
    );

    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'Sen uzman bir finansal asistansın. Kullanıcının finansal verilerini analiz et ve sorularına yanıt ver. Bir gelir veya gider bildirildiğinde add_transaction fonksiyonunu kullanarak kaydet.'
      ),
      tools: [
        Tool(functionDeclarations: [addTransactionTool])
      ],
    );
  }

  Future<String> sendMessage(String prompt) async {
    try {
      final userContent = Content.text(prompt);
      final response = await _model.generateContent([userContent]);
      
      final functionCalls = response.functionCalls.toList();
      if (functionCalls.isNotEmpty) {
        final call = functionCalls.first;
        if (call.name == 'add_transaction') {
          final title = call.args['title'] as String;
          final amount = (call.args['amount'] as num).toDouble();
          final type = call.args['type'] as String;
          final category = call.args['category'] as String? ?? 'Diğer';
          
          // İşlemi veritabanına kaydet
          await DatabaseService().addTransaction(title, amount, type, category: category);
          
          // Doğrudan onay mesajı döndür (Modeli tekrar çağırmak yerine daha hızlı ve güvenilir)
          final typeText = type == 'income' ? 'gelir' : 'gider';
          return "Anlaşıldı! **$title** için **${amount.toStringAsFixed(0)} TL** tutarında $typeText kaydını başarıyla ekledim. ✅";
        }
      }
      
      return response.text ?? "Üzgünüm, şu anda bir yanıt oluşturamadım.";
    } catch (e) {
      print("GEMINI API HATASI: $e");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('resource_exhausted') || 
          errorStr.contains('429') || 
          errorStr.contains('quota') || 
          errorStr.contains('limit')) {
        return "sizler için sunduğumuz ücretsiz api kullanım sınırına ulaştı lütfen kısa süre sonra tekrar deneyiniz";
      }
      return "Üzgünüm, bir hata oluştu: $e";
    }
  }

  Future<String> generateFinanceAnalysis({
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> bills,
    required List<Map<String, dynamic>> fixedExpenses,
    required List<Map<String, dynamic>> upcomingPayments,
  }) async {
    try {
      final prompt = """
Sen uzman bir KOBİ ve Esnaf Finans Analistisin. Aşağıdaki verileri kullanarak profesyonel, detaylı ve son derece veriye dayalı bir finansal analiz raporu hazırla.

İşletme Verileri:
1. Son Harcama ve Gelir İşlemleri:
${transactions.isEmpty ? '- Hiç kayıt bulunmuyor.' : transactions.map((t) => "- ${t['title']}: ${t['amount']} TL (${t['type'] == 'income' ? 'Gelir' : 'Gider'})").join('\n')}

2. Aktif Faturalar (Ödeme Bekleyen):
${bills.isEmpty ? '- Hiç aktif fatura bulunmuyor.' : bills.map((b) => "- ${b['title']}: ${b['amount']} TL (Son Ödeme Tarihi: ${b['dueDate']})").join('\n')}

3. Aylık Sabit Giderler (Tekrarlayan):
${fixedExpenses.isEmpty ? '- Hiç sabit gider bulunmuyor.' : fixedExpenses.map((f) => "- ${f['title']}: ${f['amount']} TL").join('\n')}

4. Yaklaşan Diğer Ödemeler:
${upcomingPayments.isEmpty ? '- Hiç yaklaşan ödeme bulunmuyor.' : upcomingPayments.map((u) => "- ${u['title']}: ${u['amount']} TL (Son Tarih: ${u['dueDate']})").join('\n')}

Lütfen tam olarak şu bölümleri içeren ve markdown formatında (kalın yazılar için ** kullanarak) bir rapor hazırla:

**Finansal Sağlık Skoru:** [Buraya verileri analiz ederek %0 ile %100 arasında bir sağlık skoru belirle ve nedenini açıkla. Örn: %82]

**Kâr/Zarar Projeksiyonu:** [Gelir ve gider kalemlerini karşılaştırarak işletmenin bu ayki kâr veya zarar durumunu, ciro/sabit gider oranını ve gidişatı analiz et.]

**Yapay Zeka Tasarruf & Nakit Önerileri:**
[İşletmenin gereksiz harcamalarını kısmak, nakit akışını güçlendirmek ve finansal durumunu optimize etmek için tam olarak bu verilere dayanarak 3 adet spesifik, aksiyona geçirilebilir öneri sun.]

Lütfen cevap verirken sadece yukarıda istenen başlıkları ve bu verilere dayalı özel analizleri kullan. Sabit kalıp cümleler yerine kullanıcının eklediği isimleri ve rakamları kullanarak kişiselleştir.
""";

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Finansal rapor şu anda oluşturulamadı.";
    } catch (e) {
      print("GEMINI FINANSAL ANALIZ HATASI: $e");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('resource_exhausted') || 
          errorStr.contains('429') || 
          errorStr.contains('quota') || 
          errorStr.contains('limit')) {
        return "sizler için sunduğumuz ücretsiz api kullanım sınırına ulaştı lütfen kısa süre sonra tekrar deneyiniz";
      }
      return "Üzgünüm, finansal analiz yapılırken bir hata oluştu: $e";
    }
  }
}
