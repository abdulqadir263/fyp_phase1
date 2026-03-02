import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../core/errors/exceptions.dart';

/// GroqService — Handles AI chat via the Groq API (LLaMA 3)
/// Strictly scoped to agriculture-only responses.
/// Replaces GeminiService for the chatbot module.
class GroqService extends GetxService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// The Groq model to use
  static const String _model = 'llama-3.3-70b-versatile';

  late final String _apiKey;
  bool _isInitialized = false;

  /// Conversation history for multi-turn chat context
  final List<Map<String, String>> _conversationHistory = [];

  /// System prompt — strictly agriculture-only
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

  /// Initialize the service with API key
  void _initialize() {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('GroqService: API key not found in .env');
        _isInitialized = false;
        return;
      }

      _apiKey = apiKey;
      _isInitialized = true;

      // Seed conversation with system prompt
      _conversationHistory.add({
        'role': 'system',
        'content': _systemPrompt,
      });

      debugPrint('GroqService: Initialized successfully');
    } catch (e) {
      debugPrint('GroqService: Initialization error - $e');
      _isInitialized = false;
    }
  }

  /// Send a message and get an agriculture-focused response
  Future<String> sendMessage(String message) async {
    if (!_isInitialized) {
      throw AIServiceException('GroqService is not initialized. Check API key.');
    }

    if (message.trim().isEmpty) {
      throw AIServiceException('Message cannot be empty');
    }

    try {
      // Add user message to conversation history
      _conversationHistory.add({
        'role': 'user',
        'content': message,
      });

      // Keep conversation history manageable (system + last 20 messages)
      if (_conversationHistory.length > 21) {
        // Keep system prompt (index 0) and trim old messages
        final systemPrompt = _conversationHistory.first;
        final recentMessages = _conversationHistory.sublist(
          _conversationHistory.length - 20,
        );
        _conversationHistory.clear();
        _conversationHistory.add(systemPrompt);
        _conversationHistory.addAll(recentMessages);
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': _conversationHistory,
          'temperature': 0.6,
          'max_tokens': 2048,
          'top_p': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage =
            data['choices']?[0]?['message']?['content'] as String? ?? '';

        if (assistantMessage.isEmpty) {
          throw AIServiceException('Empty response from Groq API');
        }

        // Add assistant response to conversation history for context
        _conversationHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });

        debugPrint('GroqService: Response received successfully');
        return assistantMessage;
      } else if (response.statusCode == 429) {
        debugPrint('GroqService: Rate limited - ${response.body}');
        throw AIServiceException(
          'Too many requests. Please wait a moment and try again.',
        );
      } else if (response.statusCode == 401) {
        debugPrint('GroqService: Unauthorized - invalid API key');
        throw AIServiceException(
          'AI service authentication failed. Please contact support.',
        );
      } else {
        debugPrint('GroqService: API error ${response.statusCode} - ${response.body}');
        throw AIServiceException(
          'Failed to get response. Please try again.',
        );
      }
    } on AIServiceException {
      // Remove the failed user message from history
      if (_conversationHistory.isNotEmpty &&
          _conversationHistory.last['role'] == 'user') {
        _conversationHistory.removeLast();
      }
      rethrow;
    } catch (e) {
      // Remove the failed user message from history
      if (_conversationHistory.isNotEmpty &&
          _conversationHistory.last['role'] == 'user') {
        _conversationHistory.removeLast();
      }
      debugPrint('GroqService: Error - $e');
      throw AIServiceException('Failed to get response: ${e.toString()}');
    }
  }

  /// Start a new chat session (clears conversation history)
  void startNewChat() {
    _conversationHistory.clear();
    // Re-add system prompt
    _conversationHistory.add({
      'role': 'system',
      'content': _systemPrompt,
    });
    debugPrint('GroqService: New chat session started');
  }

  /// Check if service is ready
  bool get isReady => _isInitialized;
}

