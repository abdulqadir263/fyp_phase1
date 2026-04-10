import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../view_model/auth_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../core/utils/responsive_helper.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ResponsiveHelper.tabletCenter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildFormSection(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
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
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Get.theme.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.agriculture, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          'app_name'.tr,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'app_subtitle'.tr,
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Obx(
      () => Container(
        key: ValueKey(controller.isLogin.value ? 'login' : 'signup'),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.isLogin.value
                  ? 'welcome_back'.tr
                  : 'create_account'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.isLogin.value
                  ? 'sign_in_to_continue'.tr
                  : 'join_farming_community'.tr,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Name Field (Signup Only)
            if (!controller.isLogin.value)
              CustomTextField(
                controller: controller.nameController,
                labelText: 'full_name'.tr,
                hintText: 'enter_full_name'.tr,
                prefixIcon: Icons.person_outline,
              ),
            if (!controller.isLogin.value) const SizedBox(height: 14),

            // Email Field
            CustomTextField(
              controller: controller.emailController,
              labelText: 'email_address'.tr,
              hintText: 'enter_email'.tr,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            // Phone Field (Signup Only)
            if (!controller.isLogin.value)
              CustomTextField(
                controller: controller.phoneController,
                labelText: 'phone_number'.tr,
                hintText: 'enter_phone'.tr,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            if (!controller.isLogin.value) const SizedBox(height: 14),

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
                  color: Colors.grey[500],
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
            const SizedBox(height: 14),

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
                    color: Colors.grey[500],
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Obx(
            () => CustomButton(
              text: controller.isLogin.value
                  ? 'sign_in'.tr
                  : 'create_account'.tr,
              onPressed: controller.submit,
              isLoading: controller.isLoading.value,
            ),
          ),
          const SizedBox(height: 14),

          // Forgot Password (Login Only)
          Obx(
            () => controller.isLogin.value
                ? GestureDetector(
                    onTap: controller.navigateToForgotPassword,
                    child: Text(
                      'forgot_password'.tr,
                      style: TextStyle(
                        color: Get.theme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Toggle Auth Mode
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.isLogin.value
                      ? 'dont_have_account'.tr
                      : 'already_have_account'.tr,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: controller.toggleAuthMode,
                  child: Text(
                    controller.isLogin.value ? 'sign_up'.tr : 'sign_in'.tr,
                    style: TextStyle(
                      color: Get.theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
