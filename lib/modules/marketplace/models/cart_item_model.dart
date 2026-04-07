/// CartItemModel — Represents a single item in the user's cart
/// Stored at: users/{uid}/cart/{productId}
class CartItemModel {
  final String productId;
  final String productName;
  final String sellerName;
  final String sellerId;
  final double price;
  final String imageUrl;
  final int quantity;
  final int availableStock;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.sellerName,
    required this.sellerId,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.availableStock,
  });

  /// From Firestore cart doc + product data merged
  factory CartItemModel.fromMap(Map<String, dynamic> data) {
    return CartItemModel(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      quantity: data['quantity'] ?? 1,
      availableStock: data['availableStock'] ?? 0,
    );
  }

  /// What gets stored in Firestore cart subcollection (minimal)
  Map<String, dynamic> toCartDocument() {
    return {'productId': productId, 'quantity': quantity};
  }

  /// Full map for local state / order items
  Map<String, dynamic> toOrderItem() {
    return {
      'productId': productId,
      'name': productName,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
    };
  }

  double get totalPrice => price * quantity;

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      productId: productId,
      productName: productName,
      sellerName: sellerName,
      sellerId: sellerId,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock,
    );
  }
}
