import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for post comments
class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String text;
  final DateTime createdAt;
  final String? parentCommentId;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl = '',
    required this.text,
    required this.createdAt,
    this.parentCommentId,
    this.replies = const [],
  });

  /// Create CommentModel from Firestore document
  factory CommentModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CommentModel(
      id: docId ?? json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      userAvatarUrl: json['userAvatarUrl'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      parentCommentId: json['parentCommentId'],
      replies: json['replies'] != null
          ? (json['replies'] as List)
                .map((r) => CommentModel.fromJson(r as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  /// Convert CommentModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentCommentId': parentCommentId,
    };
  }

  /// Create a copy with updated fields
  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? text,
    DateTime? createdAt,
    String? parentCommentId,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }

  /// Check if this is a reply to another comment
  bool get isReply => parentCommentId != null;
}
