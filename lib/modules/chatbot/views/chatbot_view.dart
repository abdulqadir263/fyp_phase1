import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/chatbot_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Chatbot view with modern UI
class ChatbotView extends GetView<ChatbotController> {
  const ChatbotView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildImagePreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  /// Build app bar with overflow fix
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'AgriBot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Compact language toggle
        Obx(() => Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: controller.toggleLanguage,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    controller.selectedLanguage.value == 'en' ? 'EN' : 'UR',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )),
        // Clear chat
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 22),
          onPressed: controller.clearChat,
          tooltip: 'Clear chat',
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  /// Build message list
  Widget _buildMessageList() {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount:
            controller.messages.length + (controller.isTyping.value ? 1 : 0),
        itemBuilder: (context, index) {
          // Show typing indicator at the end
          if (index == controller.messages.length && controller.isTyping.value) {
            return const TypingIndicator();
          }

          final message = controller.messages[index];
          return AnimatedSwitcher(
            duration: AppConstants.shortAnimation,
            child: MessageBubble(
              key: ValueKey(message.id),
              message: message,
            ),
          );
        },
      );
    });
  }

  /// Build empty state with quick action suggestions
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 80,
              color: AppConstants.primaryGreen.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "👋 Hello! I'm your farming assistant.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Ask me anything about agriculture!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              "Try asking:",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickActionChip("🌾 Wheat farming tips"),
                _buildQuickActionChip("🐛 Pest control"),
                _buildQuickActionChip("💧 Irrigation advice"),
                _buildQuickActionChip("🌱 Best crops for season"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick action chip for suggestions
  Widget _buildQuickActionChip(String label) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppConstants.primaryGreen,
        ),
      ),
      backgroundColor: AppConstants.primaryGreen.withOpacity(0.1),
      side: BorderSide(color: AppConstants.primaryGreen.withOpacity(0.3)),
      onPressed: () {
        controller.textController.text = label.replaceAll(RegExp(r'[\u{1F300}-\u{1FAD6}]', unicode: true), '').trim();
      },
    );
  }

  /// Build image preview
  Widget _buildImagePreview() {
    return Obx(() {
      if (controller.selectedImage.value == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.grey[200],
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                controller.selectedImage.value!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Image selected',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: controller.clearSelectedImage,
            ),
          ],
        ),
      );
    });
  }

  /// Build input bar
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Character count
            Obx(() => controller.characterCount.value > 0
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 4, right: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${controller.characterCount.value}/${AppConstants.maxMessageLength}',
                        style: TextStyle(
                          fontSize: 11,
                          color: controller.characterCount.value >
                                  AppConstants.maxMessageLength
                              ? Colors.red
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Image picker button
                _buildImagePickerButton(),
                const SizedBox(width: 8),
                // Text field
                Expanded(child: _buildTextField()),
                const SizedBox(width: 8),
                // Send button
                _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build image picker button
  Widget _buildImagePickerButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.add_photo_alternate_outlined,
        color: AppConstants.primaryGreen,
      ),
      onSelected: (value) {
        if (value == 'gallery') {
          controller.pickImageFromGallery();
        } else if (value == 'camera') {
          controller.takePhoto();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'gallery',
          child: Row(
            children: [
              Icon(Icons.photo_library_outlined),
              SizedBox(width: 12),
              Text('Gallery'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'camera',
          child: Row(
            children: [
              Icon(Icons.camera_alt_outlined),
              SizedBox(width: 12),
              Text('Camera'),
            ],
          ),
        ),
      ],
    );
  }

  /// Build text field
  Widget _buildTextField() {
    return Obx(() => TextField(
          controller: controller.textController,
          maxLength: AppConstants.maxMessageLength,
          maxLines: 4,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          enabled: !controller.isLoading.value,
          decoration: InputDecoration(
            hintText: controller.selectedLanguage.value == 'en'
                ? 'Ask about crops, pests, weather...'
                : 'فصلوں، کیڑوں، موسم کے بارے میں پوچھیں...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            counterText: '',
          ),
          onSubmitted: (_) => _handleSend(),
        ));
  }

  /// Build send button
  Widget _buildSendButton() {
    return Obx(() {
      final canSend = controller.canSend;

      return AnimatedContainer(
        duration: AppConstants.shortAnimation,
        child: Material(
          color: canSend ? AppConstants.primaryGreen : Colors.grey[300],
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: canSend ? _handleSend : null,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: canSend ? Colors.white : Colors.grey[500],
                      size: 22,
                    ),
            ),
          ),
        ),
      );
    });
  }

  /// Handle send action - supports text only, image only, or both
  void _handleSend() {
    final hasImage = controller.selectedImage.value != null;
    final hasText = controller.textController.text.trim().isNotEmpty;
    
    if (hasImage) {
      // Image is selected - send with image (text is optional)
      controller.sendImageMessage();
    } else if (hasText) {
      // Text only
      controller.sendTextMessage();
    }
  }
}
