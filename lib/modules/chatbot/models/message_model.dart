import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for chat messages
class MessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final String language;

  MessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
    this.language = 'en',
  });

  /// Create from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      imageUrl: json['imageUrl'] as String?,
      language: json['language'] as String? ?? 'en',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'language': language,
    };
  }

  /// Create a copy with modified fields
  MessageModel copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? imageUrl,
    String? language,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      language: language ?? this.language,
    );
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, text: $text, isUser: $isUser, timestamp: $timestamp)';
  }
}
