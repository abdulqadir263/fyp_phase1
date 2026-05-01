import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  try {
    final request = await HttpClient().postUrl(url);
    request.headers.set('Authorization', 'Bearer ' + apiKey);
    request.headers.set('Content-Type', 'application/json');

    final body = jsonEncode({
      'model': 'llama-3.1-8b-instant',
      'messages': [
        {'role': 'user', 'content': 'Say hello'}
      ]
    });
    
    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      print('Success!');
      print(responseBody);
    } else {
      print('Error ' + response.statusCode.toString() + ': ' + responseBody);
    }
  } catch (e) {
    print('Exception: ' + e.toString());
  }
}
