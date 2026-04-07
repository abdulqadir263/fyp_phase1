import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../modules/chatbot/models/message_model.dart';

/// Provider for chatbot data operations
class ChatbotProvider extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save a chat message to Firestore
  Future<void> saveMessage(String userId, MessageModel message) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.chatMessagesCollection)
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      debugPrint('ChatbotProvider: Error saving message - $e');
      rethrow;
    }
  }

  /// Get chat history for a user
  Future<List<MessageModel>> getChatHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.chatMessagesCollection)
          .orderBy('timestamp', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('ChatbotProvider: Error getting chat history - $e');
      return [];
    }
  }

  /// Clear chat history for a user
  Future<void> clearChatHistory(String userId) async {
    try {
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
    } catch (e) {
      debugPrint('ChatbotProvider: Error clearing chat history - $e');
      rethrow;
    }
  }

  /// Delete a specific message
  Future<void> deleteMessage(String userId, String messageId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.chatMessagesCollection)
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('ChatbotProvider: Error deleting message - $e');
      rethrow;
    }
  }
}
