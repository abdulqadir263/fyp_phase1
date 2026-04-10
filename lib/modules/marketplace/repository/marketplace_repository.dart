import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

/// MarketplaceRepository — All Firestore operations for marketplace
class MarketplaceRepository extends GetxService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference get _products => _fs.collection('products');
  CollectionReference get _orders => _fs.collection('orders');

  // ── Delivery fee constant ──
  static const double deliveryFee = 150.0;

  // ═══════════════════════════════════════════
  //  PRODUCTS
  // ═══════════════════════════════════════════

  /// Fetch active products with optional category & search filters
  /// Requires composite index: category ASC + createdAt DESC
  Future<List<ProductModel>> fetchProducts({
    String? category,
    String? searchQuery,
  }) async {
    try {
      Query query = _products.where('isActive', isEqualTo: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      query = query.orderBy('createdAt', descending: true);

      final snap = await query.get();
      var list = snap.docs.map((d) => ProductModel.fromDocument(d)).toList();

      // Client-side search (Firestore has no full-text search)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list = list
            .where(
              (p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q),
            )
            .toList();
      }

      debugPrint(
        '[MarketplaceRepository] fetchProducts: ${list.length} results',
      );
      return list;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        debugPrint(
          '⚠️ Missing Firestore index for products query. '
          'Deploy indexes: firebase deploy --only firestore:indexes',
        );
        return [];
      }
      rethrow;
    } catch (e) {
      debugPrint('[MarketplaceRepository] fetchProducts error: $e');
      rethrow;
    }
  }

  /// Fetch single product by ID
  Future<ProductModel?> fetchProductById(String id) async {
    final doc = await _products.doc(id).get();
    if (doc.exists) return ProductModel.fromDocument(doc);
    return null;
  }

  /// Fetch products owned by a seller
  Future<List<ProductModel>> fetchSellerProducts(String sellerId) async {
    try {
      final snap = await _products
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => ProductModel.fromDocument(d)).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        debugPrint('⚠️ Missing index for seller products query.');
        return [];
      }
      rethrow;
    }
  }

  /// Create a new product
  Future<String> createProduct(ProductModel product) async {
    final ref = await _products.add(product.toDocument());
    debugPrint('[MarketplaceRepository] Product created: ${ref.id}');
    return ref.id;
  }

  /// Update an existing product
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _products.doc(id).update(data);
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  // ═══════════════════════════════════════════
  //  CART  (subcollection under user doc)
  // ═══════════════════════════════════════════

  CollectionReference _cartRef(String uid) =>
      _fs.collection('users').doc(uid).collection('cart');

  /// Get all cart items (raw docs — controller enriches with product data)
  Future<List<Map<String, dynamic>>> fetchCartItems(String uid) async {
    final snap = await _cartRef(uid).get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['productId'] = d.id;
      return data;
    }).toList();
  }

  /// Set / update a cart item
  Future<void> setCartItem(String uid, String productId, int quantity) async {
    await _cartRef(
      uid,
    ).doc(productId).set({'productId': productId, 'quantity': quantity});
  }

  /// Remove a single cart item
  Future<void> removeCartItem(String uid, String productId) async {
    await _cartRef(uid).doc(productId).delete();
  }

  /// Clear entire cart
  Future<void> clearCart(String uid) async {
    final snap = await _cartRef(uid).get();
    final batch = _fs.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════
  //  ORDERS
  // ═══════════════════════════════════════════

  /// Place a new order
  Future<String> createOrder(OrderModel order) async {
    final ref = await _orders.add(order.toDocument());
    debugPrint('[MarketplaceRepository] Order created: ${ref.id}');
    return ref.id;
  }

  /// Fetch orders for a buyer
  Future<List<OrderModel>> fetchBuyerOrders(String buyerId) async {
    try {
      final snap = await _orders
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => OrderModel.fromDocument(d)).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        debugPrint('⚠️ Missing index for buyer orders query.');
        return [];
      }
      rethrow;
    }
  }

  /// Stream a single order for live status tracking
  Stream<OrderModel?> streamOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((snap) {
      if (snap.exists) return OrderModel.fromDocument(snap);
      return null;
    });
  }

  /// Fetch ALL orders (seller filters client-side by their sellerId in items)
  Future<List<OrderModel>> fetchAllOrders() async {
    try {
      final snap = await _orders.orderBy('createdAt', descending: true).get();
      return snap.docs.map((d) => OrderModel.fromDocument(d)).toList();
    } catch (e) {
      debugPrint('[MarketplaceRepository] fetchAllOrders error: $e');
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _orders.doc(orderId).update({'status': newStatus});
  }

  /// Reduce stock for confirmed items (batch write)
  Future<void> reduceStock(List<Map<String, dynamic>> items) async {
    final batch = _fs.batch();
    for (final item in items) {
      final ref = _products.doc(item['productId']);
      batch.update(ref, {
        'stock': FieldValue.increment(-(item['quantity'] as int)),
      });
    }
    await batch.commit();
  }
}
