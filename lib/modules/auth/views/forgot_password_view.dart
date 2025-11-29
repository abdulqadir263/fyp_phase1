import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../core/constants/app_constants.dart';

class ForgotPasswordView extends GetView<AuthController> {
  ForgotPasswordView({super.key});

  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Get email from arguments if available
    final String? initialEmail = Get.arguments as String?;
    if (initialEmail != null && initialEmail.isNotEmpty) {
      emailController.text = initialEmail;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Reset Password',
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
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() => AnimatedSwitcher(
              duration: AppConstants.mediumAnimation,
              child: _buildCurrentStep(),
            )),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (controller.forgotPasswordStep.value) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildSuccessStep();
      default:
        return _buildEmailStep();
    }
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      key: const ValueKey('email_step'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(
            icon: Icons.lock_reset_outlined,
            title: 'Reset Your Password',
            subtitle:
                'Enter your email address and we will send you a link to reset your password.',
          ),
          const SizedBox(height: 40),
          _buildEmailFormSection(),
          const SizedBox(height: 40),
          Obx(() => CustomButton(
                text: 'Send Reset Link',
                onPressed: () =>
                    controller.sendPasswordResetEmail(emailController.text.trim()),
                isLoading: controller.isLoading.value,
              )),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return SingleChildScrollView(
      key: const ValueKey('success_step'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(
            icon: Icons.mark_email_read_outlined,
            title: 'Check Your Email',
            subtitle:
                'We have sent a password reset link to ${controller.resetEmail.value}. Please check your email inbox and spam folder.',
          ),
          const SizedBox(height: 40),
          _buildEmailInfoCard(),
          const SizedBox(height: 32),
          _buildResendSection(),
          const SizedBox(height: 40),
          CustomButton(
            text: 'Back to Login',
            onPressed: () => Get.back(),
          ),
        ],
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
            color: AppConstants.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CustomTextField(
            controller: emailController,
            labelText: 'Email Address',
            hintText: 'Enter your email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure you enter the same email address you used when creating your account.',
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
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
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
            'Email Sent!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your inbox and spam folder for the password reset link. Click the link in the email to reset your password.',
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
      final timer = controller.resendTimer.value;
      return Center(
        child: Column(
          children: [
            Text(
              "Didn't receive the email?",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            timer > 0
                ? Text(
                    'Resend in $timer seconds',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : TextButton(
                    onPressed: () => controller
                        .sendPasswordResetEmail(controller.resetEmail.value),
                    child: Text(
                      'Resend Email',
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