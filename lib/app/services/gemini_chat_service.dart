import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// GeminiChatService — Handles agricultural AI chat via Google Gemini API.
///
/// Uses the `google_generative_ai` native Flutter SDK (not raw HTTP).
/// Strictly scoped to agriculture-only responses via a strong system prompt.
/// Multi-turn conversation is maintained by passing the full message history
/// on each request.
class GeminiChatService extends GetxService {
  static const String _model = 'gemini-2.0-flash';

  late GenerativeModel _geminiModel;
  late ChatSession _chatSession;
  bool _isInitialized = false;

  // ── Agriculture-only system prompt ─────────────────────────────────────────
  static const String _systemPrompt = '''
You are AgriBot, an expert agricultural advisor for Pakistani and South Asian farmers. Your ONLY purpose is to answer agriculture and farming related questions.

=== ABSOLUTE RULE: AGRICULTURE ONLY ===

Before responding, you MUST determine if the user's question is DIRECTLY related to agriculture or farming.

ALLOWED TOPICS (answer these helpfully):
• Crop cultivation, planting, harvesting, seeds, crop rotation
• Crop diseases, identification, prevention, treatment
• Pest control, pesticides, herbicides, insecticides, fungicides
• Irrigation methods, water management, drip irrigation, canal systems
• Fertilizers, soil health, composting, soil testing, nutrient management
• Livestock farming, poultry, dairy, goat, cattle, animal husbandry
• Farm equipment, tractors, agricultural machinery, maintenance
• Agricultural market prices, selling produce, mandi rates
• Agricultural policies, subsidies, Kissan cards, government schemes
• Organic farming, sustainable agriculture, permaculture
• Greenhouse farming, tunnel farming, hydroponic farming
• Weather impact SPECIFICALLY on farming and crops
• Seed varieties, hybrid seeds, best crop selection for regions
• Post-harvest handling, storage, food processing from farms
• Agricultural finance, crop loans, farm budgeting
• Weed management and control methods

STRICTLY FORBIDDEN TOPICS (always reject these):
• General greetings or casual talk ("hello", "how are you", "what's your name")
• Jokes, riddles, stories, poems, entertainment
• Politics, news, current events (unless agricultural policy)
• Movies, music, celebrities, sports, games
• Technology, programming, coding, computers, phones, apps, AI
• Personal advice, relationships, lifestyle, fashion
• General knowledge, trivia, history, geography
• Mathematics, physics, chemistry (unless directly about farming science)
• Medical/health advice (unless about livestock/farm animal health)
• Travel, tourism, restaurants, food recipes (unless farm produce processing)
• Finance, crypto, stock market (unless farm financial planning)
• General weather discussion (only crop/farm weather impacts allowed)
• Creative writing, stories, poetry
• ANY question not directly about agriculture or farming

WHEN USER ASKS A NON-AGRICULTURE QUESTION:
Reply EXACTLY with one of these (match the user's language):

English: "🌾 I'm sorry, but I can only help with agriculture and farming related questions. I can assist you with topics like crop management, pest control, irrigation, livestock, fertilizers, and other farming topics. Please ask me something about farming!"

Urdu: "🌾 معذرت، میں صرف زراعت اور کھیتی باڑی سے متعلق سوالات میں مدد کر سکتا ہوں۔ میں فصلوں، کیڑوں کی روک تھام، آبپاشی، مویشیوں، کھادوں اور دیگر زرعی موضوعات میں آپ کی مدد کر سکتا ہوں۔ براہ کرم کھیتی باڑی سے متعلق سوال پوچھیں!"

=== RESPONSE GUIDELINES (for agricultural questions only) ===

LANGUAGE:
• Detect the language of the user's message
• Reply in the SAME language the user used
• If user writes in Urdu/Roman Urdu, respond in Urdu
• Use simple vocabulary that a farmer with basic education can understand

FORMAT:
• Give practical, actionable advice
• Use bullet points for step-by-step instructions
• Mention specific product names, dosages, and timings when relevant
• Include safety precautions for chemicals/pesticides
• Mention local Pakistani/South Asian crop varieties when relevant
• Keep responses thorough but not overly long (aim for 150-300 words)

EXPERTISE AREAS:
• Major crops: wheat, rice, cotton, sugarcane, maize, potatoes, canola, mustard
• Fruits: mango, citrus, guava, dates, pomegranate, banana
• Vegetables: tomato, onion, chili, garlic, potato, peas, okra
• Livestock: buffalo, cow, goat, sheep, poultry
• Regional knowledge: Punjab, Sindh, KPK, Balochistan farming conditions

REMEMBER: You are STRICTLY an agriculture bot. If there is ANY doubt whether a question is agricultural, DECLINE it. Never break character.
''';

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  void _initialize() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('GeminiChatService: GEMINI_API_KEY not found in .env');
        _isInitialized = false;
        return;
      }

      _geminiModel = GenerativeModel(
        model: _model,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          topP: 0.9,
          maxOutputTokens: 2048,
        ),
      );

      // Start a fresh chat session with the system instruction in history
      _chatSession = _geminiModel.startChat(
        history: [
          Content.text(
              'SYSTEM INSTRUCTION:\n$_systemPrompt\n\nAcknowledge these instructions and reply only with "Understood."'),
          Content.model([TextPart('Understood.')]),
        ],
      );
      _isInitialized = true;
      debugPrint('GeminiChatService: Initialized with model $_model');
    } catch (e) {
      debugPrint('GeminiChatService: Initialization error — $e');
      _isInitialized = false;
    }
  }

  /// Send a message and get an agriculture-focused response.
  /// Throws [Exception] on failure so ChatbotController can handle it.
  Future<String> sendMessage(String message) async {
    if (!_isInitialized) {
      throw Exception(
        'AgriBot is not available right now. Please check your connection.',
      );
    }

    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    try {
      final response = await _chatSession.sendMessage(
        Content.text(message.trim()),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response received. Please try again.');
      }

      debugPrint('GeminiChatService: Response received successfully.');
      return text;
    } on GenerativeAIException catch (e) {
      debugPrint('GeminiChatService: GenerativeAIException — $e');
      // Translate common Gemini API error codes to user-friendly messages
      final msg = e.message.toLowerCase();
      if (msg.contains('quota') || msg.contains('resource_exhausted')) {
        throw Exception(
          'Usage limit reached. Please try again in a few minutes.',
        );
      } else if (msg.contains('api_key') || msg.contains('permission')) {
        throw Exception(
          'AI service authentication failed. Please contact support.',
        );
      } else if (msg.contains('safety')) {
        throw Exception(
          'Your message was blocked by safety filters. Please rephrase.',
        );
      }
      throw Exception('Failed to get a response. Please try again.');
    } catch (e) {
      debugPrint('GeminiChatService: Error — $e');
      throw Exception('Failed to get a response. Please try again.');
    }
  }

  /// Start a new chat session — clears conversation history.
  void startNewChat() {
    if (!_isInitialized) return;
    _chatSession = _geminiModel.startChat(
      history: [
        Content.text(
            'SYSTEM INSTRUCTION:\n$_systemPrompt\n\nAcknowledge these instructions and reply only with "Understood."'),
        Content.model([TextPart('Understood.')]),
      ],
    );
    debugPrint('GeminiChatService: New chat session started.');
  }

  bool get isReady => _isInitialized;
}
