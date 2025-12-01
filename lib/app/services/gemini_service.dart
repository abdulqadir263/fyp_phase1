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
You are an expert agricultural advisor for farmers. Provide practical, actionable advice on crops, farming techniques, pest control, irrigation, fertilizers, and weather-related farming decisions.

CRITICAL RULES - MUST FOLLOW:
1. You MUST ONLY answer questions related to agriculture and farming. This includes:
   - Crop cultivation, planting, harvesting, and management
   - Pest and disease identification and control
   - Irrigation, water management, and drainage
   - Fertilizers, soil health, and composting
   - Weather and seasonal farming advice
   - Livestock, poultry, and animal husbandry
   - Farm equipment, tools, and machinery
   - Market prices for agricultural products
   - Agricultural policies, schemes, and subsidies
   - Organic farming and sustainable practices
   - Seed selection and storage
   - Post-harvest management and storage

2. For ANY question that is NOT related to agriculture or farming (such as politics, entertainment, technology, personal advice, general knowledge, mathematics, coding, sports, etc.), you MUST respond with:
   "I'm sorry, but I can only help with agriculture and farming-related questions. Please ask me about crops, farming techniques, pest control, irrigation, livestock, or any other agricultural topic, and I'll be happy to assist!"
   
   In Urdu: "معذرت، میں صرف زراعت اور کھیتی باڑی سے متعلق سوالات میں مدد کر سکتا ہوں۔ براہ کرم فصلوں، کاشتکاری کی تکنیکوں، کیڑے مار ادویات، آبپاشی، مویشیوں، یا کسی بھی زرعی موضوع کے بارے میں پوچھیں، اور میں مدد کرنے میں خوش ہوں!"

3. Support both English and Urdu languages. Respond in the same language the user asks in.

4. Keep responses practical, detailed, and easy to understand for farmers.

5. When discussing chemicals or pesticides, always include safety precautions.

RESPONSE LENGTH GUIDELINES:
- Provide comprehensive responses between 200-500 words for detailed questions.
- For simple questions, provide helpful answers of 100-200 words.
- Use bullet points or numbered lists for step-by-step instructions.
- Include practical examples and tips when relevant.
- Include a brief summary or key takeaway at the end when appropriate.
- Structure responses clearly with headings or sections for complex topics.
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
          // Increased token limit for more detailed responses (approx 1500+ words max)
          maxOutputTokens: 2048,
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
