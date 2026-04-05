import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../core/utils/responsive_helper.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 28),
                      _buildFormSection(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // App Icon
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Get.theme.primaryColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Get.theme.primaryColor.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.agriculture,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),

        // App Title
        Text(
          'app_name'.tr,
          style: Get.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),

        // App Subtitle
        Text(
          'app_subtitle'.tr,
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'welcome_back'.tr,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Obx(() => AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey(controller.isLogin.value ? 'login' : 'signup'),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Title
            Text(
              controller.isLogin.value ? 'welcome_back'.tr : 'create_account'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.isLogin.value
                  ? 'sign_in_to_continue'.tr
                  : 'join_farming_community'.tr,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),

            // Name Field (Signup Only)
            if (!controller.isLogin.value)
              CustomTextField(
                controller: controller.nameController,
                labelText: 'full_name'.tr,
                hintText: 'enter_full_name'.tr,
                prefixIcon: Icons.person_outline,
              ),

            if (!controller.isLogin.value) const SizedBox(height: 16),

            // Email Field
            CustomTextField(
              controller: controller.emailController,
              labelText: 'email_address'.tr,
              hintText: 'enter_email'.tr,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone Field (Signup Only)
            if (!controller.isLogin.value)
              CustomTextField(
                controller: controller.phoneController,
                labelText: 'phone_number'.tr,
                hintText: 'enter_phone'.tr,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

            if (!controller.isLogin.value) const SizedBox(height: 16),

            // Password Field
            CustomTextField(
              controller: controller.passwordController,
              labelText: 'password'.tr,
              hintText: 'enter_password'.tr,
              prefixIcon: Icons.lock_outline,
              obscureText: !controller.isPasswordVisible.value,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isPasswordVisible.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password Field (Signup Only)
            if (!controller.isLogin.value)
              CustomTextField(
                controller: controller.confirmPasswordController,
                labelText: 'confirm_password'.tr,
                hintText: 'reenter_password'.tr,
                prefixIcon: Icons.lock_outline,
                obscureText: !controller.isConfirmPasswordVisible.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordVisible.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
              ),

            // Role selection removed from signup - now handled on separate RoleSelectionView screen
          ],
        ),
      ),
    ));
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
        // Submit Button
        Obx(() => CustomButton(
          text: controller.isLogin.value ? 'sign_in'.tr : 'create_account'.tr,
          onPressed: controller.submit,
          isLoading: controller.isLoading.value,
        )),

        const SizedBox(height: 16),

        // Forgot Password (Login Only)
        Obx(() => controller.isLogin.value
            ? GestureDetector(
          onTap: controller.navigateToForgotPassword,
          child: Text(
            'forgot_password'.tr,
            style: TextStyle(
              color: Get.theme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        )
            : const SizedBox.shrink()),

        const SizedBox(height: 24),

        // Toggle Auth Mode
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.isLogin.value
                    ? 'dont_have_account'.tr
                    : 'already_have_account'.tr,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: controller.toggleAuthMode,
                child: Text(
                  controller.isLogin.value ? 'sign_up'.tr : 'sign_in'.tr,
                  style: TextStyle(
                    color: Get.theme.primaryColor,
                    fontWeight: FontWeight.bold,
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

}