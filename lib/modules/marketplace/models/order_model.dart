import 'package:cloud_firestore/cloud_firestore.dart';

/// OrderModel — Represents a COD order placed by a farmer
class OrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final List<Map<String, dynamic>>
  items; // [{productId, name, price, quantity, sellerId}]
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String deliveryAddress;
  final String phone;
  final String status; // pending | confirmed | shipped | delivered | cancelled
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.phone,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      phone: data['phone'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'items': items,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get statusLabel => '${status[0].toUpperCase()}${status.substring(1)}';

  /// All valid order statuses
  static const List<String> statuses = [
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled',
  ];
}
