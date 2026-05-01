import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // Gemini API endpoint for content generation
  if (apiKey.isEmpty) {
    print('No API key.');
    exit(1);
  }

  try {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );

    final content = [Content.text('Say hello')];
    final response = await model.generateContent(content);
    
    print('Response: ' + (response.text ?? 'null'));
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
