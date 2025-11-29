import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for community posts
class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int commentsCount;
  final int bookmarksCount;
  final List<String> bookmarkedBy;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl = '',
    required this.title,
    required this.description,
    this.imageUrls = const [],
    required this.category,
    required this.createdAt,
    this.updatedAt,
    this.commentsCount = 0,
    this.bookmarksCount = 0,
    this.bookmarkedBy = const [],
  });

  /// Create PostModel from Firestore document
  factory PostModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return PostModel(
      id: docId ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      userAvatarUrl: json['userAvatarUrl'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      category: json['category'] ?? 'crops',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      commentsCount: json['commentsCount'] ?? 0,
      bookmarksCount: json['bookmarksCount'] ?? 0,
      bookmarkedBy: List<String>.from(json['bookmarkedBy'] ?? []),
    );
  }

  /// Convert PostModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'commentsCount': commentsCount,
      'bookmarksCount': bookmarksCount,
      'bookmarkedBy': bookmarkedBy,
    };
  }

  /// Create a copy with updated fields
  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? title,
    String? description,
    List<String>? imageUrls,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? commentsCount,
    int? bookmarksCount,
    List<String>? bookmarkedBy,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      commentsCount: commentsCount ?? this.commentsCount,
      bookmarksCount: bookmarksCount ?? this.bookmarksCount,
      bookmarkedBy: bookmarkedBy ?? this.bookmarkedBy,
    );
  }

  /// Check if post is bookmarked by user
  bool isBookmarkedBy(String userId) {
    return bookmarkedBy.contains(userId);
  }

  /// Available categories
  static List<String> get categories => [
    'crops',
    'livestock',
    'equipment',
    'weather',
    'market',
  ];

  /// Get category display name
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'crops':
        return 'Crops';
      case 'livestock':
        return 'Livestock';
      case 'equipment':
        return 'Equipment';
      case 'weather':
        return 'Weather';
      case 'market':
        return 'Market Prices';
      default:
        return 'Other';
    }
  }
}
