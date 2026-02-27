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

/// Controller for creating and editing posts
/// Handles:
/// - Post form management
/// - Image picking
/// - Post creation and upload
/// - Post editing (pre-fill + update)
/// - Navigation after creation/edit
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

  // ==================== Edit Mode State ====================
  /// Whether we are in edit mode (true) or create mode (false)
  final RxBool isEditMode = false.obs;

  /// The post ID being edited (null in create mode)
  String? editingPostId;

  /// Get current user ID from auth provider
  String? get currentUserId => _authProvider.currentUser.value?.uid;

  /// Get current user name for displaying on posts
  String get currentUserName => _authProvider.currentUser.value?.name ?? 'User';

  /// Get current user avatar URL
  String get currentUserAvatar => _authProvider.currentUser.value?.profileImage ?? '';

  @override
  void onInit() {
    super.onInit();
    // Check if edit arguments were passed via Get.arguments
    final args = Get.arguments;
    if (args is PostModel) {
      _initEditMode(args);
    }
  }

  /// Initialize edit mode with existing post data
  void _initEditMode(PostModel post) {
    isEditMode.value = true;
    editingPostId = post.id;
    titleController.text = post.title;
    descriptionController.text = post.description;
    postCategory.value = post.category;
    // NOTE: existing images are URLs, not local files — we don't re-pick them.
    // Edit mode only changes text fields and category.
  }

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
    isEditMode.value = false;
    editingPostId = null;
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

  /// Submit — either creates a new post or updates an existing one
  Future<void> submitPost() async {
    if (isEditMode.value) {
      await _updatePost();
    } else {
      await createPost();
    }
  }

  /// Update existing post (edit mode)
  Future<void> _updatePost() async {
    if (isCreatingPost.value) return;
    if (!validateForm()) return;
    if (editingPostId == null) return;

    try {
      isCreatingPost.value = true;

      if (Get.isRegistered<PostController>()) {
        await Get.find<PostController>().editPost(
          postId: editingPostId!,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          category: postCategory.value.trim(),
        );
      }

      if (_isDisposed) return;

      clearForm();
      Get.back();
    } catch (e) {
      if (!_isDisposed) {
        AppSnackbar.error('Failed to update post');
      }
      debugPrint('Error updating post: $e');
    } finally {
      if (!_isDisposed) {
        isCreatingPost.value = false;
      }
    }
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
        category: postCategory.value.trim(),
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final postId = await _communityService.createPost(post);
      
      if (_isDisposed) return;

      if (postId != null) {
        AppSnackbar.success('Post created successfully');
        clearForm();
        
        // Navigate back to community screen first
        Get.back();
        
        // Refresh posts list after navigation completes
        // Using Future.microtask to ensure navigation finishes first
        Future.microtask(() {
          if (Get.isRegistered<PostController>()) {
            Get.find<PostController>().fetchPosts(refresh: true);
          }
        });
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
