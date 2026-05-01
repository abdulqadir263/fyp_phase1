import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/services/groq_service.dart';
import '../../../modules/auth/repository/auth_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../models/message_model.dart';
import '../repository/chat_repository.dart';

/// ChatbotController (ViewModel) — manages chatbot UI state and orchestrates
/// communication between the view, GeminiChatService, and ChatRepository.
///
/// Agriculture-only enforcement is handled by the system prompt inside
/// GeminiChatService. This controller is purely UI + persistence.
class ChatbotController extends GetxController {
  final GroqService _groqService = Get.find<GroqService>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();

  // Text controller for input
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Reactive variables
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isTyping = false.obs;
  final RxString selectedLanguage = 'en'.obs;
  final RxInt characterCount = 0.obs;
  final RxBool hasValidInput = false.obs;

  // Welcome messages
  static const String _welcomeEn =
      '👋 Hello! I\'m AgriBot, your farming assistant.\n'
      'Ask me anything about crops, pests, irrigation, livestock, and more!';
  static const String _welcomeUr =
      '👋 السلام علیکم! میں AgriBot ہوں، آپ کا زرعی معاون۔\n'
      'فصلوں، کیڑوں، آبپاشی، مویشیوں وغیرہ کے بارے میں کچھ بھی پوچھیں!';

  String? get _userId {
    final uid = _authRepository.currentUser.value?.uid;
    return (uid != null && uid != 'guest_user') ? uid : null;
  }

  @override
  void onInit() {
    super.onInit();
    textController.addListener(_onTextChanged);
    _addWelcomeMessage();
    _loadChatHistory();
  }

  @override
  void onClose() {
    textController.removeListener(_onTextChanged);
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onTextChanged() {
    final text = textController.text.trim();
    characterCount.value = textController.text.length;
    hasValidInput.value =
        text.isNotEmpty && text.length <= AppConstants.maxMessageLength;
  }

  void _addWelcomeMessage() {
    messages.add(MessageModel(
      id: 'welcome',
      text: selectedLanguage.value == 'en' ? _welcomeEn : _welcomeUr,
      isUser: false,
      timestamp: DateTime.now(),
      language: selectedLanguage.value,
    ));
  }

  Future<void> _loadChatHistory() async {
    final userId = _userId;
    if (userId == null) return;

    final history = await _chatRepository.loadChatHistory(userId);
    if (history.isNotEmpty) {
      messages.clear();
      messages.addAll(history);
      _scrollToBottom();
    }
  }

  // ── Send message ────────────────────────────────────────────────────────────

  Future<void> sendTextMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isLoading.value) return;

    if (text.length > AppConstants.maxMessageLength) {
      Get.snackbar(
        'Too long',
        'Message cannot exceed ${AppConstants.maxMessageLength} characters',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    HapticFeedback.lightImpact();

    textController.clear();
    characterCount.value = 0;
    hasValidInput.value = false;

    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      language: selectedLanguage.value,
    );

    messages.add(userMessage);
    _scrollToBottom();

    final userId = _userId;
    if (userId != null) {
      await _chatRepository.saveMessage(userId, userMessage);
    }

    await _getAIResponse(text);
  }

  // ── AI response via Gemini ──────────────────────────────────────────────────

  Future<void> _getAIResponse(String text) async {
    isLoading.value = true;
    isTyping.value = true;

    try {
      final response = await _groqService.sendMessage(text);
      isTyping.value = false;

      final botMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        language: selectedLanguage.value,
      );

      messages.add(botMessage);
      _scrollToBottom();

      final userId = _userId;
      if (userId != null) {
        await _chatRepository.saveMessage(userId, botMessage);
      }
    } catch (e) {
      isTyping.value = false;
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Error handling ──────────────────────────────────────────────────────────

  void _handleError(dynamic error) {
    // Extract the user-friendly message thrown by GroqService
    String errorText;
    if (error is Exception) {
      errorText = error.toString().replaceFirst('Exception: ', '');
    } else {
      errorText = selectedLanguage.value == 'en'
          ? '❌ Sorry, something went wrong. Please try again.'
          : '❌ معذرت، کوئی خرابی ہوئی۔ براہ کرم دوبارہ کوشش کریں۔';
    }

    messages.add(MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '❌ $errorText',
      isUser: false,
      timestamp: DateTime.now(),
      language: selectedLanguage.value,
    ));
    _scrollToBottom();
    debugPrint('[ChatbotController] error: $error');
  }

  // ── Language toggle ─────────────────────────────────────────────────────────

  void toggleLanguage() {
    selectedLanguage.value = selectedLanguage.value == 'en' ? 'ur' : 'en';
    HapticFeedback.selectionClick();
  }

  // ── Scroll ──────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: AppConstants.shortAnimation,
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Clear chat ──────────────────────────────────────────────────────────────

  Future<void> clearChat() async {
    Get.defaultDialog(
      title: 'Clear Chat',
      middleText: 'Are you sure you want to clear all messages?',
      textCancel: 'Cancel',
      textConfirm: 'Clear',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        messages.clear();
        _addWelcomeMessage();

        final userId = _userId;
        if (userId != null) {
          await _chatRepository.clearHistory(userId);
        }

        // Reset Groq conversation so history doesn't persist across sessions
        _groqService.startNewChat();
      },
    );
  }

  bool get canSend => hasValidInput.value && !isLoading.value;
}
