import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/message_model.dart';

/// ChatRepository — handles all Firestore operations for chat messages.
///
/// Responsibilities:
/// - Load chat history from Firestore
/// - Save individual messages to Firestore
/// - Clear chat history from Firestore
class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load the most recent chat messages for a user.
  Future<List<MessageModel>> loadChatHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.chatMessagesCollection)
          .orderBy('timestamp', descending: false)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('ChatRepository: Error loading chat history: $e');
      return [];
    }
  }

  /// Save a single message to Firestore.
  Future<void> saveMessage(String userId, MessageModel message) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.chatMessagesCollection)
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      debugPrint('ChatRepository: Error saving message: $e');
    }
  }

  /// Delete all chat messages for a user.
  Future<void> clearHistory(String userId) async {
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
      debugPrint('ChatRepository: Error clearing chat history: $e');
    }
  }
}
