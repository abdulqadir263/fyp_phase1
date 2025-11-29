import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/services/gemini_service.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../models/message_model.dart';

/// Controller for chatbot functionality
class ChatbotController extends GetxController {
  final GeminiService _geminiService = Get.find<GeminiService>();
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Text controller for input
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Reactive variables
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isTyping = false.obs;
  final RxString selectedLanguage = 'en'.obs;
  final RxInt characterCount = 0.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);

  // Welcome message
  static const String welcomeMessageEn =
      "👋 Hello! I'm your farming assistant. Ask me anything about agriculture!";
  static const String welcomeMessageUr =
      "👋 السلام علیکم! میں آپ کا زرعی معاون ہوں۔ کھیتی باڑی کے بارے میں کچھ بھی پوچھیں!";

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

  /// Listener for text changes
  void _onTextChanged() {
    characterCount.value = textController.text.length;
  }

  /// Add welcome message
  void _addWelcomeMessage() {
    final welcomeMessage = MessageModel(
      id: 'welcome',
      text: selectedLanguage.value == 'en' ? welcomeMessageEn : welcomeMessageUr,
      isUser: false,
      timestamp: DateTime.now(),
      language: selectedLanguage.value,
    );
    messages.add(welcomeMessage);
  }

  /// Load chat history from Firestore
  Future<void> _loadChatHistory() async {
    try {
      final userId = _authProvider.currentUser.value?.uid;
      if (userId == null || userId == 'guest_user') return;

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.chatMessagesCollection)
          .orderBy('timestamp', descending: false)
          .limit(50)
          .get();

      if (snapshot.docs.isNotEmpty) {
        messages.clear();
        messages.addAll(
          snapshot.docs.map((doc) => MessageModel.fromJson(doc.data())).toList(),
        );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  /// Save message to Firestore
  Future<void> _saveMessage(MessageModel message) async {
    try {
      final userId = _authProvider.currentUser.value?.uid;
      if (userId == null || userId == 'guest_user') return;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.chatMessagesCollection)
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }

  /// Send text message
  Future<void> sendTextMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isLoading.value) return;

    // Validate message length
    if (text.length > AppConstants.maxMessageLength) {
      Get.snackbar(
        'Error',
        'Message cannot exceed ${AppConstants.maxMessageLength} characters',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Clear input
    textController.clear();
    characterCount.value = 0;

    // Create user message
    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      language: selectedLanguage.value,
    );

    messages.add(userMessage);
    _scrollToBottom();
    await _saveMessage(userMessage);

    // Get AI response
    await _getAIResponse(text);
  }

  /// Send message with image
  Future<void> sendImageMessage() async {
    if (selectedImage.value == null) return;

    final text = textController.text.trim();
    
    // Validate message length for image messages too
    if (text.length > AppConstants.maxMessageLength) {
      Get.snackbar(
        'Error',
        'Message cannot exceed ${AppConstants.maxMessageLength} characters',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Clear input
    textController.clear();
    characterCount.value = 0;

    // Create user message with image
    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.isEmpty ? 'Analyzing image...' : text,
      isUser: true,
      timestamp: DateTime.now(),
      language: selectedLanguage.value,
    );

    messages.add(userMessage);
    _scrollToBottom();

    // Get AI response with image
    await _getAIResponseWithImage(text, selectedImage.value!);

    // Clear selected image
    selectedImage.value = null;
  }

  /// Get AI response for text message
  Future<void> _getAIResponse(String text) async {
    try {
      isLoading.value = true;
      isTyping.value = true;

      final response = await _geminiService.sendMessage(text);

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
      await _saveMessage(botMessage);
    } catch (e) {
      isTyping.value = false;
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Get AI response with image
  Future<void> _getAIResponseWithImage(String prompt, File image) async {
    try {
      isLoading.value = true;
      isTyping.value = true;

      final response = await _geminiService.sendMessageWithImage(prompt, image);

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
      await _saveMessage(botMessage);
    } catch (e) {
      isTyping.value = false;
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle errors
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

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      Get.snackbar(
        'Error',
        'Failed to take photo',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Clear selected image
  void clearSelectedImage() {
    selectedImage.value = null;
  }

  /// Toggle language
  void toggleLanguage() {
    selectedLanguage.value = selectedLanguage.value == 'en' ? 'ur' : 'en';
    HapticFeedback.selectionClick();
  }

  /// Scroll to bottom of chat
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

  /// Clear chat history
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

        // Clear from Firestore
        try {
          final userId = _authProvider.currentUser.value?.uid;
          if (userId != null && userId != 'guest_user') {
            final batch = _firestore.batch();
            final docs = await _firestore
                .collection(AppConstants.usersCollection)
                .doc(userId)
                .collection(AppConstants.chatMessagesCollection)
                .get();

            for (var doc in docs.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
          }
        } catch (e) {
          debugPrint('Error clearing chat history: $e');
        }

        // Start new chat session
        _geminiService.startNewChat();
      },
    );
  }

  /// Validate message length
  bool _isMessageValid(String text) {
    return text.isNotEmpty && text.length <= AppConstants.maxMessageLength;
  }

  /// Check if send button should be enabled
  bool get canSend {
    final text = textController.text.trim();
    final hasValidText = text.isNotEmpty && text.length <= AppConstants.maxMessageLength;
    final hasImage = selectedImage.value != null;
    
    return (hasValidText || hasImage) && !isLoading.value;
  }
}
