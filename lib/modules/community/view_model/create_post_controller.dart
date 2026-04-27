import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/data/services/cloudinary_service.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/post_model.dart';
import '../repository/community_repository.dart';
import 'post_controller.dart';

// dart:io removed — XFile used throughout for web compatibility
class CreatePostController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final CommunityRepository _communityRepository = Get.find<CommunityRepository>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // XFile instead of File
  final RxList<XFile> selectedImages = <XFile>[].obs;

  // Cached bytes per image for preview — avoids repeated readAsBytes() on rebuild
  final RxList<Uint8List> selectedImageBytes = <Uint8List>[].obs;

  final RxString postCategory = 'crops'.obs;
  final RxBool isCreatingPost = false.obs;
  bool _isDisposed = false;

  final RxBool isEditMode = false.obs;
  String? editingPostId;

  String? get currentUserId => _authRepository.currentUser.value?.uid;
  String get currentUserName => _authRepository.currentUser.value?.name ?? 'User';
  String get currentUserAvatar => _authRepository.currentUser.value?.profileImage ?? '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PostModel) _initEditMode(args);
  }

  void _initEditMode(PostModel post) {
    isEditMode.value = true;
    editingPostId = post.id;
    titleController.text = post.title;
    descriptionController.text = post.description;
    postCategory.value = post.category;
  }

  @override
  void onClose() {
    _isDisposed = true;
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> pickImages() async {
    if (selectedImages.length >= 2) {
      AppSnackbar.info('Maximum 2 images allowed');
      return;
    }
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1024, maxHeight: 1024, imageQuality: 80,
      );
      if (pickedFiles.isNotEmpty) {
        final remaining = 2 - selectedImages.length;
        final toAdd = pickedFiles.take(remaining).toList();
        for (final xf in toAdd) {
          final bytes = await xf.readAsBytes();
          selectedImages.add(xf);
          selectedImageBytes.add(bytes);
        }
      }
    } catch (e) {
      AppSnackbar.error('Failed to pick images');
      debugPrint('pickImages error: $e');
    }
  }

  Future<void> takePhoto() async {
    if (selectedImages.length >= 2) {
      AppSnackbar.info('Maximum 2 images allowed');
      return;
    }
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024, maxHeight: 1024, imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        selectedImages.add(picked);
        selectedImageBytes.add(bytes);
      }
    } catch (e) {
      AppSnackbar.error('Failed to take photo');
      debugPrint('takePhoto error: $e');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      selectedImageBytes.removeAt(index);
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedImages.clear();
    selectedImageBytes.clear();
    postCategory.value = 'crops';
    isEditMode.value = false;
    editingPostId = null;
  }

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

  Future<void> submitPost() async {
    if (isEditMode.value) {
      await _updatePost();
    } else {
      await createPost();
    }
  }

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
      if (!_isDisposed) AppSnackbar.error('Failed to update post');
      debugPrint('_updatePost error: $e');
    } finally {
      if (!_isDisposed) isCreatingPost.value = false;
    }
  }

  Future<void> createPost() async {
    if (isCreatingPost.value) return;
    if (!validateForm()) return;

    final user = _authRepository.currentUser.value;
    if (user == null || user.uid.isEmpty) {
      AppSnackbar.info('Please login to create posts');
      return;
    }
    if (!user.isProfileComplete) {
      AppSnackbar.warning('Please complete your profile first to create a post.');
      return;
    }
    if (user.userType == 'farmer' &&
        (user.cropsGrown == null || user.cropsGrown!.isEmpty)) {
      AppSnackbar.warning('Please add crops to your profile before posting.');
      return;
    }

    try {
      isCreatingPost.value = true;

      List<String> imageUrls = [];

      if (selectedImages.isNotEmpty) {
        final cloudinaryService = Get.find<CloudinaryService>();

        // Upload using cached bytes — no dart:io File needed
        final uploadFutures = List.generate(selectedImages.length, (i) {
          final xf = selectedImages[i];
          final bytes = selectedImageBytes[i];
          final fileName = xf.name.isNotEmpty
              ? xf.name
              : 'post_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

          return cloudinaryService
              .uploadImage(bytes, fileName, folder: 'post_images')
              .catchError((e) {
            debugPrint('Image upload error: $e');
            return null;
          });
        });

        final results = await Future.wait(uploadFutures);
        imageUrls = results.whereType<String>().toList();

        final failedCount = selectedImages.length - imageUrls.length;
        if (failedCount > 0 && imageUrls.isNotEmpty) {
          AppSnackbar.info('$failedCount image(s) failed to upload');
        }
      }

      if (_isDisposed) return;

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

      final postId = await _communityRepository.createPost(post);

      if (_isDisposed) return;

      if (postId != null) {
        AppSnackbar.success('Post created successfully');
        clearForm();
        Get.back();
        Future.microtask(() {
          if (Get.isRegistered<PostController>()) {
            Get.find<PostController>().fetchPosts(refresh: true);
          }
        });
      } else {
        AppSnackbar.error('Failed to create post');
      }
    } catch (e) {
      if (!_isDisposed) AppSnackbar.error('Failed to create post');
      debugPrint('createPost error: $e');
    } finally {
      if (!_isDisposed) isCreatingPost.value = false;
    }
  }
}