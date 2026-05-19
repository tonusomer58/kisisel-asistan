import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = "AIzaSyDmx2FS_LUvCKEvpgoRzL5wqR1M8EnhJrs"; 
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  try {
    final response = await http.get(url);
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = (data['models'] as List).map((m) => m['name']).toList();
      print('Available models: $models');
    } else {
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
