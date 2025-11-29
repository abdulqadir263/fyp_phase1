import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// Service for Gemini AI integration
class GeminiService extends GetxService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  /// System instruction for agriculture-focused responses
  static const String _systemInstruction = '''
You are an expert agricultural advisor for farmers. Provide practical, actionable advice on crops, farming techniques, pest control, irrigation, fertilizers, and weather-related farming decisions.

IMPORTANT RULES:
1. ONLY answer agriculture-related questions including:
   - Crop cultivation and management
   - Pest and disease control
   - Irrigation and water management
   - Fertilizers and soil health
   - Weather and seasonal farming advice
   - Livestock and animal husbandry
   - Farm equipment and tools
   - Market prices for agricultural products
   - Agricultural policies and schemes

2. If asked non-agricultural questions, politely decline and redirect to farming topics.

3. Support both English and Urdu languages. Respond in the same language the user asks in.

4. Keep responses concise, practical, and easy to understand for farmers.

5. When discussing chemicals or pesticides, always include safety precautions.
''';

  @override
  void onInit() {
    super.onInit();
    _initializeModel();
  }

  /// Initialize the Gemini model
  void _initializeModel() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw AIServiceException('Gemini API key not found in environment');
      }

      _model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: apiKey,
        systemInstruction: Content.text(_systemInstruction),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );

      _chatSession = _model.startChat();

      if (AppConstants.enableLogging) {
        print('GeminiService: Initialized successfully');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('GeminiService: Initialization error - $e');
      }
    }
  }

  /// Send a text message and get a response
  Future<String> sendMessage(String message) async {
    try {
      if (message.trim().isEmpty) {
        throw AIServiceException('Message cannot be empty');
      }

      final response = await _chatSession.sendMessage(Content.text(message));
      final text = response.text;

      if (text == null || text.isEmpty) {
        throw AIServiceException('Empty response from AI');
      }

      if (AppConstants.enableLogging) {
        print('GeminiService: Response received successfully');
      }

      return text;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('GeminiService: Error sending message - $e');
      }
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Failed to get response: ${e.toString()}');
    }
  }

  /// Send a message with an image and get a response
  Future<String> sendMessageWithImage(String prompt, File image) async {
    try {
      if (!await image.exists()) {
        throw AIServiceException('Image file not found');
      }

      final imageBytes = await image.readAsBytes();
      final mimeType = _getMimeType(image.path);

      final content = Content.multi([
        TextPart(prompt.isEmpty ? 'Analyze this image and provide agricultural advice.' : prompt),
        DataPart(mimeType, imageBytes),
      ]);

      final response = await _model.generateContent([content]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        throw AIServiceException('Empty response from AI');
      }

      if (AppConstants.enableLogging) {
        print('GeminiService: Image response received successfully');
      }

      return text;
    } catch (e) {
      if (AppConstants.enableLogging) {
        print('GeminiService: Error sending image - $e');
      }
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Failed to analyze image: ${e.toString()}');
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Start a new chat session (clears history)
  void startNewChat() {
    _chatSession = _model.startChat();
    if (AppConstants.enableLogging) {
      print('GeminiService: New chat session started');
    }
  }
}
