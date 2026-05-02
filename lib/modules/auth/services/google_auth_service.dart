import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Centralised Google Sign-In + canonical users/{uid} Firestore management.
/// Used by Expert, Seller, and Farmer controllers.
class GoogleAuthService {
  final _googleSignIn = GoogleSignIn();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ── Google OAuth ──────────────────────────────────────────────────────────

  /// Returns [UserCredential] on success, null if the user cancelled.
  Future<UserCredential?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
  }

  // ── Canonical users/{uid} collection ─────────────────────────────────────

  /// Creates or merges a users/{uid} document.
  /// Safe to call on both signup and re-login (merge: true).
  Future<void> upsertUserDoc({
    required String uid,
    required String email,
    required String role,
    bool profileComplete = false,
  }) async {
    await _db.collection('users').doc(uid).set(
      {
        'uid': uid,
        'email': email,
        'role': role,
        'profileComplete': profileComplete,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Flips profileComplete = true after profile setup is done.
  Future<void> markProfileComplete(String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({'profileComplete': true});
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  /// Returns a user-friendly message for any auth-related error.
  /// Returns empty string when the user simply cancelled Google Sign-In.
  String mapError(Object e) {
    final s = e.toString();
    if (s.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (s.contains('user-not-found')) {
      return 'No account found. Please sign up.';
    }
    if (s.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    }
    // User pressed Back / cancelled in the Google picker
    if (s.contains('sign_in_canceled') ||
        s.contains('canceled') ||
        s.contains('cancel') ||
        s.contains('PlatformException(sign_in_failed')) {
      return '';
    }
    return 'Something went wrong. Please try again.';
  }
}
