import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../view_model/chatbot_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Chatbot view — clean, production-grade messaging UI
class ChatbotView extends GetView<ChatbotController> {
  const ChatbotView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco_rounded, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'agribot'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'online'.tr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Obx(
          () => TextButton(
            onPressed: controller.toggleLanguage,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(40, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              controller.selectedLanguage.value == 'en' ? 'EN' : 'UR',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 22),
          onPressed: controller.clearChat,
          tooltip: 'Clear chat',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        itemCount:
            controller.messages.length + (controller.isTyping.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.messages.length &&
              controller.isTyping.value) {
            return const TypingIndicator();
          }
          final message = controller.messages[index];
          return MessageBubble(key: ValueKey(message.id), message: message);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.agriculture_rounded,
                size: 56,
                color: AppConstants.primaryGreen.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "👋 Hello! I'm your farming assistant.",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "Ask me anything about agriculture!",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Text(
              "Try asking:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
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

  Widget _buildQuickActionChip(String label) {
    return InkWell(
      onTap: () {
        controller.textController.text = label
            .replaceAll(RegExp(r'[\u{1F300}-\u{1FAD6}]', unicode: true), '')
            .trim();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Character count
            Obx(
              () => controller.characterCount.value > 0
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
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildTextField()),
                const SizedBox(width: 8),
                _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: TextField(
          controller: controller.textController,
          maxLength: AppConstants.maxMessageLength,
          maxLines: 4,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          enabled: !controller.isLoading.value,
          style: const TextStyle(fontSize: 15, height: 1.4),
          decoration: InputDecoration(
            hintText: controller.selectedLanguage.value == 'en'
                ? 'Ask about crops, pests, weather...'
                : 'فصلوں، کیڑوں، موسم کے بارے میں پوچھیں...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            counterText: '',
          ),
          onSubmitted: (_) => _handleSend(),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Obx(() {
      final canSend = controller.canSend;

      return SizedBox(
        width: 46,
        height: 46,
        child: Material(
          color: canSend ? AppConstants.primaryGreen : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(23),
          child: InkWell(
            onTap: canSend ? _handleSend : null,
            borderRadius: BorderRadius.circular(23),
            child: Center(
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: canSend ? Colors.white : Colors.grey[500],
                      size: 20,
                    ),
            ),
          ),
        ),
      );
    });
  }

  void _handleSend() {
    if (controller.textController.text.trim().isNotEmpty) {
      controller.sendTextMessage();
    }
  }
}
