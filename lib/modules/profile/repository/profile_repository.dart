import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/services/firebase_service.dart';
import '../../../app/data/services/cloudinary_service.dart';

/// ProfileRepository — handles all data operations for the Profile module.
///
/// Responsibilities:
/// - Save profile data to Firestore (via FirebaseService)
/// - Upload profile images to Cloudinary (via CloudinaryService)
class ProfileRepository {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();

  /// Persist user profile to Firestore.
  Future<void> saveProfile(UserModel user) async {
    await _firebaseService.saveUserData(user);
  }

  /// Upload an image file to Cloudinary and return the CDN URL.
  /// Returns null if upload fails.
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      return await _cloudinaryService.uploadImage(
        imageFile,
        folder: 'profile_images',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ProfileRepository: Image upload error → $e');
      }
      return null;
    }
  }
}
