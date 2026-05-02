import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/custom_text_field.dart';
import '../../../app/widgets/google_sign_in_icon.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/farmer_auth_controller.dart';

/// Farmer auth screen — three paths:
///   • Email / Password (signup or login, no email verification)
///   • Continue with Google
///   • Continue as Guest (anonymous)
class FarmerAuthView extends GetView<FarmerAuthController> {
  const FarmerAuthView({super.key});

  static const _green = AppConstants.primaryGreen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
              controller.isLogin.value ? 'Farmer Login' : 'Farmer Signup',
              style: const TextStyle(color: _green),
            )),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(
          () => Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCredentialsCard(),
                        const SizedBox(height: 16),
                        _buildErrorText(),
                        const SizedBox(height: 8),
                        _buildEmailSubmitButton(),
                        const SizedBox(height: 16),
                        _buildDivider(),
                        const SizedBox(height: 16),
                        _buildGoogleButton(),
                        const SizedBox(height: 12),
                        _buildGuestButton(),
                        const SizedBox(height: 20),
                        _buildToggleMode(),
                      ],
                    ),
                  ),
                ),
              ),
              if (controller.isLoading.value)
                Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Email / Password card ──────────────────────────────────────────────────

  Widget _buildCredentialsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grass, color: _green, size: 20),
              ),
              const SizedBox(width: 10),
              Obx(() => Text(
                    controller.isLogin.value
                        ? 'Login to your account'
                        : 'Create an Account',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800]),
                  )),
            ],
          ),
          const SizedBox(height: 24),

          CustomTextField(
            controller: controller.emailCtrl,
            labelText: 'Email Address *',
            hintText: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: controller.validateEmail,
          ),
          const SizedBox(height: 14),

          Obx(() => CustomTextField(
                controller: controller.passwordCtrl,
                labelText: 'Password *',
                hintText: 'Minimum 8 characters',
                prefixIcon: Icons.lock_outline,
                obscureText: !controller.isPasswordVisible.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () => controller.isPasswordVisible.toggle(),
                ),
              )),

          Obx(() {
            if (controller.isLogin.value) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: 14),
                Obx(() => CustomTextField(
                      controller: controller.confirmPasswordCtrl,
                      labelText: 'Confirm Password *',
                      hintText: 'Re-enter password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !controller.isConfirmPasswordVisible.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isConfirmPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: Colors.grey[500],
                        ),
                        onPressed: () =>
                            controller.isConfirmPasswordVisible.toggle(),
                      ),
                    )),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildErrorText() {
    return Obx(() {
      final err = controller.errorMessage.value;
      if (err.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(err,
                  style:
                      TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmailSubmitButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : controller.submitEmailAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _green.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Obx(() => Text(
                  controller.isLogin.value ? 'Login' : 'Create Account',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                )),
          ),
        ));
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed:
            controller.isLoading.value ? null : controller.signInWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GoogleSignInIcon(),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3C4043)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed:
            controller.isLoading.value ? null : controller.signInAnonymously,
        icon: Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
        label: Text(
          'Continue as Guest (no account needed)',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700]),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              controller.isLogin.value
                  ? "Don't have an account? "
                  : 'Already have an account? ',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            GestureDetector(
              onTap: () {
                controller.isLogin.toggle();
                controller.errorMessage.value = '';
              },
              child: Text(
                controller.isLogin.value ? 'Sign up' : 'Login',
                style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ));
  }
}
