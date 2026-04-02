import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../core/values/constants.dart';
import '../models/user_model.dart';

// Firebase interaction layer — all auth and Firestore calls live here.
// Controllers and providers call this; they never touch Firebase directly.
class FirebaseService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Private property
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ NEW: Public getter for FirebaseAuth instance
  FirebaseAuth get auth => _auth; // ✅ This fixes the error

  // Current user ka stream get karna
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password se signup
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
      throw _getErrorMessage(e);
    }
  }

  // Email/Password se login
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
      throw _getErrorMessage(e);
    }
  }

  /// Sign out current user (works for both email and anonymous users)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Anonymous sign-in for the guest farmer flow.
  /// Returns a real Firebase UserCredential with a permanent UID.
  /// The UID stays the same across app restarts until the user signs out.
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // User ko Firestore mein save/update karna
  Future<void> saveUserData(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.USERS_COLLECTION)
          .doc(user.uid)
          .set(user.toDocument(), SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save user data: ${e.toString()}';
    }
  }

  // User ka data get karna by UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection(AppConstants.USERS_COLLECTION).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user data: ${e.toString()}';
    }
  }

  // Firebase errors ko user-friendly messages mein convert karna
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  // Add this method to the FirebaseService class

// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e);
    }
  }

}