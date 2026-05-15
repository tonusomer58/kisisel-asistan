import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';

class GeminiService {
  static const String _apiKey = "AIzaSyB_CSePn-T9CZ6MqfohTJOtfkhzScDXYtk";
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
      return "Üzgünüm, bir hata oluştu: $e";
    }
  }
}
