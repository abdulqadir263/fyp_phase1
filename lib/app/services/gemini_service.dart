import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// Service for Gemini AI integration
class GeminiService extends GetxService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

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
        generationConfig: GenerationConfig(
          // Slightly lower temperature for more coherent, complete responses
          temperature: 0.6,
          // Increased token limit for longer, more detailed responses (approx 3000+ words max)
          maxOutputTokens: 4096,
          // top-k helps with response quality and completeness
          topK: 40,
          // top-p for nucleus sampling - helps generate complete responses
          topP: 0.95,
        ),
      );

      _chatSession = _model.startChat();

      if (AppConstants.enableLogging) {
        debugPrint('GeminiService: Initialized successfully');
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('GeminiService: Initialization error - $e');
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
        debugPrint('GeminiService: Response received successfully');
      }

      return text;
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('GeminiService: Error sending message - $e');
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
        TextPart(
          prompt.isEmpty
              ? 'Analyze this image and provide agricultural advice.'
              : prompt,
        ),
        DataPart(mimeType, imageBytes),
      ]);

      final response = await _model.generateContent([content]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        throw AIServiceException('Empty response from AI');
      }

      if (AppConstants.enableLogging) {
        debugPrint('GeminiService: Image response received successfully');
      }

      return text;
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('GeminiService: Error sending image - $e');
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
      debugPrint('GeminiService: New chat session started');
    }
  }
}
