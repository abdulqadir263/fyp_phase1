import 'package:cloud_firestore/cloud_firestore.dart';

/// ProductModel — Represents a product listed on the marketplace
class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String name;
  final String category; // seeds | fertilizers | pesticides
  final double price;
  final int stock;
  final String description;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.description,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'seeds',
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ProductModel copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? name,
    String? category,
    double? price,
    int? stock,
    String? description,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Fixed marketplace categories
  static const List<String> categories = ['seeds', 'fertilizers', 'pesticides'];

  /// Display-friendly category name
  String get categoryLabel =>
      '${category[0].toUpperCase()}${category.substring(1)}';
}

