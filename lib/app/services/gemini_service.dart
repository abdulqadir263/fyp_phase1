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
You are AgriBot, an expert agricultural advisor. Your ONLY purpose is to answer agriculture and farming questions.

=== CRITICAL INSTRUCTION: TOPIC FILTERING (MUST FOLLOW) ===

STEP 1 - BEFORE EVERY RESPONSE, you MUST first analyze if the question is about agriculture:
Ask yourself: "Is this question DIRECTLY about farming, crops, livestock, agricultural practices, or agricultural topics?"
- If YES: Proceed to answer the question helpfully
- If NO: You MUST decline with the rejection message below. Do NOT answer the question.

STEP 2 - AGRICULTURE CHECK CRITERIA:
A question is ONLY agricultural if it's about:
• Crop cultivation, planting, harvesting, seeds, or crop diseases
• Pest control, pesticides, herbicides, or plant diseases
• Irrigation, water management for farms, or agricultural drainage
• Fertilizers, soil health, composting, or farming soil
• Livestock, poultry, dairy farming, or animal husbandry
• Farm equipment, agricultural machinery, or farming tools
• Agricultural market prices or selling farm produce
• Agricultural policies or farming subsidies
• Organic farming or sustainable agricultural practices
• Greenhouse or hydroponic farming
• Weather impacts SPECIFICALLY on farming/crops

STEP 3 - NON-AGRICULTURE TOPICS (ALWAYS REJECT):
You MUST decline ANY question about:
• General greetings or casual conversation (e.g., "how are you", "hello", "what's up")
• Jokes, riddles, or entertainment
• Politics, news, current events (except agricultural news)
• Movies, music, celebrities, sports, games
• Technology, programming, coding, computers, phones, apps
• Personal advice, relationships, lifestyle tips
• General knowledge, trivia, history, geography
• Mathematics, physics, chemistry (unless directly about farming)
• Medical or health advice (unless about livestock/farm animals)
• Travel, tourism, restaurants, food recipes
• Finance, investments, cryptocurrency (unless farm financial planning)
• Weather in general (only farm/crop weather impacts allowed)
• Any creative writing, stories, or poems
• Any question that does NOT directly relate to farming or agriculture

STEP 4 - REJECTION RESPONSE (USE EXACTLY AS WRITTEN):
For English: "I apologize, but I can only assist with agriculture and farming-related questions. My expertise is strictly limited to crops, farming techniques, pest control, irrigation, livestock, and other agricultural topics. Please ask me a question related to farming or agriculture, and I'll be happy to help!"

For Urdu: "معذرت، میں صرف زراعت اور کھیتی باڑی سے متعلق سوالات میں مدد کر سکتا ہوں۔ میری مہارت صرف فصلوں، کاشتکاری کی تکنیکوں، کیڑوں کی روک تھام، آبپاشی، مویشیوں اور زرعی موضوعات تک محدود ہے۔ براہ کرم زراعت سے متعلق سوال پوچھیں، اور میں مدد کرنے میں خوش ہوں گا!"

=== RESPONSE GUIDELINES (FOR AGRICULTURAL QUESTIONS ONLY) ===

LANGUAGE:
• Detect the language of the user's question (English or Urdu)
• Always respond in the SAME language the user used
• Use simple, farmer-friendly vocabulary

RESPONSE FORMAT:
• Provide complete and thorough responses
• Use bullet points for step-by-step instructions
• Include practical, actionable advice
• When discussing chemicals/pesticides, include safety precautions

REMEMBER: When in doubt about whether a topic is agricultural, DECLINE the question. Your role is STRICTLY agricultural advice only.
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
          // top-k helps with response quality and completeness
          topK: 40,
          // top-p for nucleus sampling - helps generate complete responses
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
