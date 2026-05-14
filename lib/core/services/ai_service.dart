import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = "AIzaSyB_CSePn-T9CZ6MqfohTJOtfkhzScDXYtk";
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'Sen uzman bir finansal asistansın. Kullanıcının gelir, gider, tasarruf ve nakit akışı gibi konulardaki sorularına kısa, net ve profesyonel cevaplar vermelisin. Asla finansal tavsiye (yatırım) vermemelisin.'
      ),
    );
  }

  Future<String> sendMessage(String prompt) async {
    try {

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Üzgünüm, şu anda bir yanıt oluşturamadım.";
    } catch (e) {
      throw Exception("Bağlantı hatası oluştu: $e");
    }
  }
}
