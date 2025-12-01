import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/chatbot_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Chatbot view with modern UI - text input only
class ChatbotView extends GetView<ChatbotController> {
  const ChatbotView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        curve: Curves.easeInOut,
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  /// Build app bar with smooth styling
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Get.back(),
        splashRadius: 20,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AgriBot',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
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
        // Smooth language toggle
        Obx(() => AnimatedContainer(
              duration: AppConstants.shortAnimation,
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.toggleLanguage,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: Colors.white24,
                  highlightColor: Colors.white10,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      controller.selectedLanguage.value == 'en' ? 'EN' : 'UR',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            )),
        // Clear chat button
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 22),
          onPressed: controller.clearChat,
          tooltip: 'Clear chat',
          splashRadius: 20,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// Build message list with smooth scrolling
  Widget _buildMessageList() {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        physics: const BouncingScrollPhysics(),
        itemCount:
            controller.messages.length + (controller.isTyping.value ? 1 : 0),
        itemBuilder: (context, index) {
          // Show typing indicator at the end
          if (index == controller.messages.length && controller.isTyping.value) {
            return const TypingIndicator();
          }

          final message = controller.messages[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AppConstants.mediumAnimation,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.agriculture_rounded,
                  size: 64,
                  color: AppConstants.primaryGreen.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "👋 Hello! I'm your farming assistant.",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Ask me anything about agriculture!",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Try asking:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
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

  /// Build quick action chip for suggestions with smooth interaction
  Widget _buildQuickActionChip(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          controller.textController.text = label.replaceAll(RegExp(r'[\u{1F300}-\u{1FAD6}]', unicode: true), '').trim();
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: AppConstants.primaryGreen.withOpacity(0.1),
        highlightColor: AppConstants.primaryGreen.withOpacity(0.05),
        child: AnimatedContainer(
          duration: AppConstants.shortAnimation,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppConstants.primaryGreen.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryGreen.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppConstants.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }

  /// Build input bar with smooth styling
  Widget _buildInputBar() {
    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Character count with smooth transition
            Obx(() => AnimatedSwitcher(
                  duration: AppConstants.shortAnimation,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        child: child,
                      ),
                    );
                  },
                  child: controller.characterCount.value > 0
                      ? Padding(
                          key: const ValueKey('char-count'),
                          padding: const EdgeInsets.only(bottom: 6, right: 12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedDefaultTextStyle(
                              duration: AppConstants.shortAnimation,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: controller.characterCount.value >
                                        AppConstants.maxMessageLength
                                    ? Colors.red
                                    : Colors.grey[500],
                              ),
                              child: Text(
                                '${controller.characterCount.value}/${AppConstants.maxMessageLength}',
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                )),
            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text field
                Expanded(child: _buildTextField()),
                const SizedBox(width: 10),
                // Send button
                _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build text field with smooth focus animation
  Widget _buildTextField() {
    return Obx(() => AnimatedContainer(
          duration: AppConstants.shortAnimation,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: controller.isLoading.value
                  ? Colors.grey[300]!
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller.textController,
            maxLength: AppConstants.maxMessageLength,
            maxLines: 4,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            enabled: !controller.isLoading.value,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: controller.selectedLanguage.value == 'en'
                  ? 'Ask about crops, pests, weather...'
                  : 'فصلوں، کیڑوں، موسم کے بارے میں پوچھیں...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              counterText: '',
            ),
            onSubmitted: (_) => _handleSend(),
          ),
        ));
  }

  /// Build send button with smooth animations
  Widget _buildSendButton() {
    return Obx(() {
      final canSend = controller.canSend;

      return AnimatedContainer(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeOutCubic,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: canSend
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryGreen,
                    Color.fromARGB(
                      AppConstants.primaryGreen.a.toInt(),
                      AppConstants.primaryGreen.r.toInt(),
                      (AppConstants.primaryGreen.g * 0.85).toInt(),
                      AppConstants.primaryGreen.b.toInt(),
                    ),
                  ],
                )
              : null,
          color: canSend ? null : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(25),
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: AppConstants.primaryGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canSend ? _handleSend : null,
            borderRadius: BorderRadius.circular(25),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: Center(
              child: AnimatedSwitcher(
                duration: AppConstants.shortAnimation,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: controller.isLoading.value
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        key: const ValueKey('send'),
                        color: canSend ? Colors.white : Colors.grey[500],
                        size: 22,
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Handle send action - text only
  void _handleSend() {
    final hasText = controller.textController.text.trim().isNotEmpty;
    
    if (hasText) {
      controller.sendTextMessage();
    }
  }
}
