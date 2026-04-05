import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';

class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    // Email is pre-filled by AuthController.navigateToForgotPassword()
    // No local TextEditingController needed — avoids a memory leak

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(
          'reset_password'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: controller.closeCurrentScreen,
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6FFF8), Color(0xFFF9FAFF)],
            ),
          ),
          child: ResponsiveHelper.tabletCenter(
            child: Obx(() => AnimatedSwitcher(
                  duration: AppConstants.mediumAnimation,
                  child: _buildCurrentStep(),
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    // resetStep 0 = enter email, 1 = success screen
    return controller.resetStep.value == 0
        ? _buildEmailStep()
        : _buildSuccessStep();
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      key: const ValueKey('email_step'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(
                  icon: Icons.lock_reset_outlined,
                  title: 'reset_your_password'.tr,
                  subtitle: 'enter_email_reset'.tr,
                ),
                const SizedBox(height: 28),
                _buildEmailFormSection(),
                const SizedBox(height: 28),
                Obx(() => CustomButton(
                      text: 'send_reset_link'.tr,
                      onPressed: () => controller.sendPasswordResetEmail(
                        controller.forgotEmailController.text.trim(),
                      ),
                      isLoading: controller.isLoading.value,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    return SingleChildScrollView(
      key: const ValueKey('success_step'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(
                  icon: Icons.mark_email_read_outlined,
                  title: 'check_your_email'.tr,
                  subtitle:
                      'We have sent a password reset link to ${controller.resetEmailSentTo.value}. Please check your inbox and spam folder.',
                ),
                const SizedBox(height: 28),
                _buildEmailInfoCard(),
                const SizedBox(height: 24),
                _buildResendSection(),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'back_to_login'.tr,
                  onPressed: controller.closeCurrentScreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppConstants.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            size: 30,
            color: AppConstants.primaryGreen,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Uses forgotEmailController from the controller (properly disposed)
          CustomTextField(
            controller: controller.forgotEmailController,
            labelText: 'email_address'.tr,
            hintText: 'enter_email'.tr,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'same_email_info'.tr,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFE7C9)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: Colors.green[600],
          ),
          const SizedBox(height: 16),
          Text(
            'email_sent'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'check_inbox_spam'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Obx(() {
      final cooldown = controller.resendCooldown.value;  // renamed from resendTimer
      return Center(
        child: Column(
          children: [
            Text(
              'didnt_receive_email'.tr,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            if (cooldown > 0)
              Text(
                'Resend in $cooldown ${'seconds'.tr}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              TextButton(
                onPressed: () => controller
                    .sendPasswordResetEmail(controller.resetEmailSentTo.value),
                child: Text(
                  'resend_email'.tr,
                  style: TextStyle(
                    color: AppConstants.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}