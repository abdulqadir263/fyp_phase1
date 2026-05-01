import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Handles Email+Password auth for the Seller role.
class SellerAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<bool> reloadAndCheckVerification() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> saveSellerProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db
        .collection('sellers')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getSellerProfile(String uid) async {
    final doc = await _db.collection('sellers').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  User? get currentUser => _auth.currentUser;

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':   return 'email_already_in_use';
      case 'invalid-email':          return 'invalid_email';
      case 'wrong-password':
      case 'invalid-credential':     return 'wrong_password';
      case 'user-not-found':         return 'user_not_found';
      case 'weak-password':          return 'weak_password';
      case 'too-many-requests':      return 'too_many_requests';
      case 'network-request-failed': return 'network_error';
      default:                       return e.message ?? 'auth_error';
    }
  }
}
