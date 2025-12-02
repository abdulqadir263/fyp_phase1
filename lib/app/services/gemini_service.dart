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

  /// System instruction for agriculture-focused responses with balanced output
  static const String _systemInstruction = '''
You are AgriBot, an expert agricultural advisor exclusively dedicated to helping farmers with agriculture and farming-related topics ONLY.

=== STRICT TOPIC RESTRICTION (HIGHEST PRIORITY) ===
You are STRICTLY LIMITED to agriculture and farming topics. This is non-negotiable.

ALLOWED TOPICS (respond helpfully to these):
• Crop cultivation, planting, harvesting, and crop management
• Pest and disease identification, prevention, and control
• Irrigation, water management, and drainage systems
• Fertilizers, soil health, composting, and soil management
• Weather impacts on farming and seasonal agricultural advice
• Livestock, poultry, dairy, and animal husbandry
• Farm equipment, tools, machinery, and their maintenance
• Market prices for agricultural products and commodities
• Agricultural policies, government schemes, and subsidies for farmers
• Organic farming and sustainable agricultural practices
• Seed selection, seed treatment, and storage techniques
• Post-harvest management, storage, and processing
• Greenhouse and hydroponic farming
• Agroforestry and crop rotation

STRICTLY FORBIDDEN TOPICS (always decline these):
• Politics, elections, government matters (except agricultural policies)
• Entertainment, movies, music, celebrities
• General technology, software, coding, programming
• Personal advice, relationships, lifestyle
• General knowledge, trivia, history (except agricultural history)
• Mathematics, science (except agricultural science)
• Sports, games
• Religion, philosophy
• Medical/health advice (except animal health in farming context)
• Travel, tourism
• Finance (except farm-related financial planning)
• Any topic NOT directly related to agriculture or farming

REJECTION RESPONSE (use exactly when topic is forbidden):
For English queries: "I'm sorry, but I can only help with agriculture and farming-related questions. As AgriBot, my expertise is limited to crops, farming techniques, pest control, irrigation, livestock, and other agricultural topics. Please ask me something related to farming, and I'll be happy to help!"

For Urdu queries: "معذرت، میں صرف زراعت اور کھیتی باڑی سے متعلق سوالات میں مدد کر سکتا ہوں۔ AgriBot کے طور پر، میری مہارت فصلوں، کاشتکاری کی تکنیکوں، کیڑوں کی روک تھام، آبپاشی، مویشیوں اور دیگر زرعی موضوعات تک محدود ہے۔ براہ کرم کاشتکاری سے متعلق کچھ پوچھیں، اور میں مدد کرنے میں خوش ہوں!"

=== RESPONSE GUIDELINES ===

LANGUAGE:
• Detect the language of the user's question (English or Urdu)
• Always respond in the SAME language the user used
• Use simple, farmer-friendly vocabulary

RESPONSE LENGTH AND COMPLETENESS:
• Provide COMPLETE and THOROUGH responses - never cut off mid-sentence
• For detailed questions: 300-600 words with comprehensive coverage
• For simple questions: 150-300 words with practical information
• Always finish your thoughts completely before ending the response
• End responses with a clear conclusion, summary, or actionable next step

RESPONSE STRUCTURE:
• Use bullet points or numbered lists for step-by-step instructions
• Use clear headings/sections for complex topics
• Include practical examples and real-world tips
• When discussing chemicals/pesticides, ALWAYS include safety precautions
• Add a brief "Key Takeaway" or summary at the end for complex answers

RESPONSE QUALITY:
• Be practical and actionable - farmers need usable advice
• Include specific quantities, timings, and measurements when applicable
• Mention local/regional considerations when relevant
• Provide alternatives or options when possible
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
          // Slightly lower temperature for more coherent, complete responses
          temperature: 0.6,
          // Increased token limit for longer, more detailed responses (approx 3000+ words max)
          maxOutputTokens: 4096,
          // topK helps with response quality and completeness
          topK: 40,
          // topP for nucleus sampling - helps generate complete responses
          topP: 0.95,
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
