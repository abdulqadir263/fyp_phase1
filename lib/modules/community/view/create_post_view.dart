import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../view_model/create_post_controller.dart';
import '../models/post_model.dart';

// dart:io removed — Image.memory used with cached bytes for web compatibility
class CreatePostView extends GetView<CreatePostController> {
  const CreatePostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: ResponsiveHelper.tabletCenter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              Obx(() => controller.isEditMode.value
                  ? const SizedBox.shrink()
                  : _buildImagePicker()),
              const SizedBox(height: 24),
              _buildPublishButton(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Obx(() => Text(
          controller.isEditMode.value ? 'Edit Post' : 'Create Post')),
      centerTitle: true,
      backgroundColor: AppConstants.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          controller.clearForm();
          Get.back();
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Title',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
        const SizedBox(height: 8),
        TextField(
          controller: controller.titleController,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Enter post title',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppConstants.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
        const SizedBox(height: 8),
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PostModel.categories.map((category) {
            final isSelected = controller.postCategory.value == category;
            return ChoiceChip(
              label: Text(PostModel.getCategoryDisplayName(category)),
              selected: isSelected,
              selectedColor: AppConstants.primaryGreen.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppConstants.primaryGreen : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppConstants.primaryGreen
                    : Colors.grey[300]!,
              ),
              onSelected: (selected) {
                if (selected) controller.postCategory.value = category;
              },
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
        const SizedBox(height: 8),
        TextField(
          controller: controller.descriptionController,
          maxLength: 1000,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Share your thoughts with the community...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppConstants.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Images (max 2)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: Colors.grey[800])),
            Obx(() => Text('${controller.selectedImages.length}/2',
                style: TextStyle(color: Colors.grey[500], fontSize: 14))),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() => Column(
          children: [
            ...controller.selectedImageBytes.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                // ✅ Uint8List bytes passed — no File, no dart:io
                child: _buildImageThumbnail(entry.value, entry.key),
              );
            }),
            if (controller.selectedImages.length < 2) _buildAddImageButton(),
          ],
        )),
      ],
    );
  }

  // ✅ Uint8List instead of File — Image.memory works on web + mobile
  Widget _buildImageThumbnail(Uint8List bytes, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Image.memory(
              bytes,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => controller.removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey[400], size: 32),
            const SizedBox(height: 4),
            Text('Add Image',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppConstants.primaryGreen),
              title: Text('choose_from_gallery'.tr),
              onTap: () {
                Get.back();
                controller.pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppConstants.primaryGreen),
              title: const Text('Take Photo'),
              onTap: () {
                Get.back();
                controller.takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isCreatingPost.value
            ? null
            : controller.submitPost,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: controller.isCreatingPost.value
            ? const SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ))
            : Text(
            controller.isEditMode.value ? 'Save Changes' : 'Publish Post',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    ));
  }
}