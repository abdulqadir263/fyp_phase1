import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/data/services/cloudinary_service.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';
import 'post_controller.dart';

/// Controller for creating new posts
/// Handles:
/// - Post form management
/// - Image picking
/// - Post creation and upload
/// - Navigation after creation
class CreatePostController extends GetxController {
  /// Auth provider to access current user data
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  
  /// Community service for Firebase operations
  final CommunityService _communityService = Get.find<CommunityService>();
  
  /// Image picker for selecting post images
  final ImagePicker _imagePicker = ImagePicker();

  /// Controller for post title input
  final TextEditingController titleController = TextEditingController();
  
  /// Controller for post description input
  final TextEditingController descriptionController = TextEditingController();
  
  /// List of images selected for new post
  final RxList<File> selectedImages = <File>[].obs;
  
  /// Category selected for new post
  final RxString postCategory = 'crops'.obs;
  
  /// Shows loading indicator while creating post
  final RxBool isCreatingPost = false.obs;
  
  /// Flag to track if controller is still active
  bool _isDisposed = false;

  /// Get current user ID from auth provider
  String? get currentUserId => _authProvider.currentUser.value?.uid;

  /// Get current user name for displaying on posts
  String get currentUserName => _authProvider.currentUser.value?.name ?? 'User';

  /// Get current user avatar URL
  String get currentUserAvatar => _authProvider.currentUser.value?.profileImage ?? '';

  @override
  void onClose() {
    _isDisposed = true;
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Pick images from gallery
  Future<void> pickImages() async {
    if (selectedImages.length >= 2) {
      AppSnackbar.info('Maximum 2 images allowed');
      return;
    }

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = 2 - selectedImages.length;
        final filesToAdd = pickedFiles.take(remainingSlots);
        selectedImages.addAll(filesToAdd.map((xf) => File(xf.path)));
      }
    } catch (e) {
      AppSnackbar.error('Failed to pick images');
      debugPrint('Error picking images: $e');
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    if (selectedImages.length >= 2) {
      AppSnackbar.info('Maximum 2 images allowed');
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        selectedImages.add(File(pickedFile.path));
      }
    } catch (e) {
      AppSnackbar.error('Failed to take photo');
      debugPrint('Error taking photo: $e');
    }
  }

  /// Remove selected image
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  /// Clear create post form
  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedImages.clear();
    postCategory.value = 'crops';
  }

  /// Validate create post form
  bool validateForm() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty || title.length < 5) {
      AppSnackbar.error('Title must be at least 5 characters');
      return false;
    }

    if (title.length > 100) {
      AppSnackbar.error('Title cannot exceed 100 characters');
      return false;
    }

    if (description.isEmpty || description.length < 20) {
      AppSnackbar.error('Description must be at least 20 characters');
      return false;
    }

    if (description.length > 1000) {
      AppSnackbar.error('Description cannot exceed 1000 characters');
      return false;
    }

    return true;
  }

  /// Create new post
  /// Uses parallel image uploads for better performance
  Future<void> createPost() async {
    // Prevent double submission
    if (isCreatingPost.value) return;
    
    if (!validateForm()) return;
    if (currentUserId == null || currentUserId == 'guest_user') {
      AppSnackbar.info('Please login to create posts');
      return;
    }

    try {
      isCreatingPost.value = true;

      // Upload images to Cloudinary in parallel for better performance
      List<String> imageUrls = [];
      if (selectedImages.isNotEmpty) {
        final cloudinaryService = Get.find<CloudinaryService>();
        final uploadFutures = selectedImages.map(
          (image) => cloudinaryService.uploadImage(image, folder: 'post_images').catchError((e) {
            debugPrint('Error uploading image: $e');
            return null;
          }),
        );
        final results = await Future.wait(uploadFutures);
        imageUrls = results.whereType<String>().toList();
        
        // Warn user if some images failed to upload
        final failedCount = selectedImages.length - imageUrls.length;
        if (failedCount > 0 && imageUrls.isNotEmpty) {
          AppSnackbar.info('$failedCount image(s) failed to upload');
        } else if (failedCount > 0 && imageUrls.isEmpty) {
          // All images failed, but continue with post creation without images
          debugPrint('All image uploads failed, continuing with text-only post');
        }
      }
      
      if (_isDisposed) return;

      // Create post model
      final post = PostModel(
        id: '',
        userId: currentUserId!,
        userName: currentUserName,
        userAvatarUrl: currentUserAvatar,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        imageUrls: imageUrls,
        category: postCategory.value,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final postId = await _communityService.createPost(post);
      
      if (_isDisposed) return;

      if (postId != null) {
        AppSnackbar.success('Post created successfully');
        clearForm();
        
        // Navigate back to community screen
        Get.back();
        
        // Refresh posts list
        if (Get.isRegistered<PostController>()) {
          Get.find<PostController>().fetchPosts(refresh: true);
        }
      } else {
        AppSnackbar.error('Failed to create post');
      }
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to create post');
      }
      debugPrint('Error creating post: $e');
    } finally {
      if (!_isDisposed) {
        isCreatingPost.value = false;
      }
    }
  }
}
