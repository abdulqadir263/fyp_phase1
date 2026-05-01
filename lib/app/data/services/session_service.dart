import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Determines the authenticated role of the current Firebase user by
/// checking role-specific Firestore collections in order:
///   farmers/{uid} → experts/{uid} → sellers/{uid}
///
/// This is the ONLY place that reads role docs at startup.
class SessionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns 'farmer' | 'expert' | 'seller' | null
  Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final uid = user.uid;

    try {
      final farmerDoc = await _db.collection('farmers').doc(uid).get();
      if (farmerDoc.exists) return 'farmer';

      final expertDoc = await _db.collection('experts').doc(uid).get();
      if (expertDoc.exists) return 'expert';

      final sellerDoc = await _db.collection('sellers').doc(uid).get();
      if (sellerDoc.exists) return 'seller';

      return null; // Corrupted state
    } catch (e) {
      if (kDebugMode) debugPrint('SessionService.getCurrentUserRole error: $e');
      return null;
    }
  }

  /// Fetch raw map for a given role collection.
  Future<Map<String, dynamic>?> getUserData(String role, String uid) async {
    try {
      final doc = await _db.collection('${role}s').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      if (kDebugMode) debugPrint('SessionService.getUserData error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}
