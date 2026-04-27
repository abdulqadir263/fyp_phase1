import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/data/services/firebase_service.dart';
import '../../../app/data/services/cloudinary_service.dart';

// dart:io File removed — XFile works on web + mobile both
class ProfileRepository {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();

  Future<void> saveProfile(UserModel user) async {
    await _firebaseService.saveUserData(user);
  }

  // XFile instead of File — reads bytes cross-platform
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final String fileName = imageFile.name.isNotEmpty
          ? imageFile.name
          : 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      return await _cloudinaryService.uploadImage(
        bytes,
        fileName,
        folder: 'profile_images',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileRepository: image upload error → $e');
      return null;
    }
  }
}