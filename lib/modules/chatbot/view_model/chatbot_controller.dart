import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/services/groq_service.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../models/message_model.dart';
import '../repository/chat_repository.dart';

/// ChatbotController (ViewModel) — manages chatbot UI state and orchestrates
/// communication between the view, GroqService, and ChatRepository.
///
/// No direct Firebase/Firestore calls — all data ops go through ChatRepository.
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

  // Welcome message
  static const String welcomeMessageEn =
      "👋 Hello! I'm your farming assistant. Ask me anything about agriculture!";
  static const String welcomeMessageUr =
      "👋 السلام علیکم! میں آپ کا زرعی معاون ہوں۔ کھیتی باڑی کے بارے میں کچھ بھی پوچھیں!";

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
    final welcomeMessage = MessageModel(
      id: 'welcome',
      text: selectedLanguage.value == 'en'
          ? welcomeMessageEn
          : welcomeMessageUr,
      isUser: false,
      timestamp: DateTime.now(),
      language: selectedLanguage.value,
    );
    messages.add(welcomeMessage);
  }

  /// Load chat history via repository
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

  /// Send text message
  Future<void> sendTextMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isLoading.value) return;

    if (text.length > AppConstants.maxMessageLength) {
      Get.snackbar(
        'Error',
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

    // Save via repository
    final userId = _userId;
    if (userId != null) {
      await _chatRepository.saveMessage(userId, userMessage);
    }

    await _getAIResponse(text);
  }

  /// Get AI response (via Groq — agriculture only)
  Future<void> _getAIResponse(String text) async {
    try {
      isLoading.value = true;
      isTyping.value = true;

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

  void _handleError(dynamic error) {
    final errorMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: selectedLanguage.value == 'en'
          ? '❌ Sorry, I encountered an error. Please try again.'
          : '❌ معذرت، کوئی خرابی ہوئی۔ براہ کرم دوبارہ کوشش کریں۔',
      isUser: false,
      timestamp: DateTime.now(),
      language: selectedLanguage.value,
    );

    messages.add(errorMessage);
    _scrollToBottom();
    debugPrint('Chatbot error: $error');
  }

  void toggleLanguage() {
    selectedLanguage.value = selectedLanguage.value == 'en' ? 'ur' : 'en';
    HapticFeedback.selectionClick();
  }

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

  /// Clear chat via repository
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

        _groqService.startNewChat();
      },
    );
  }

  bool get canSend {
    return hasValidInput.value && !isLoading.value;
  }
}
