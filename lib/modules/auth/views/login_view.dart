import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';

class LoginView extends GetView<AuthController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header Section
              _buildHeaderSection(),

              const SizedBox(height: 40),

              // Form Section
              _buildFormSection(),

              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),

              const SizedBox(height: 32),

              // Guest Login Section
              _buildGuestLoginSection(),
            ],
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Get.theme.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Get.theme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
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
          'Aasaan Kisaan',
          style: Get.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),

        // App Subtitle
        Text(
          'Your Smart Farming Companion',
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Obx(() => AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(controller.isLogin.value ? 'login' : 'signup'),
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
            // Form Title
            Text(
              controller.isLogin.value ? 'Welcome Back' : 'Create Account',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.isLogin.value
                  ? 'Sign in to continue'
                  : 'Join our farming community',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Name Field (Signup Only)
            if (!controller.isLogin.value)
              CustomTextField(
                controller: controller.nameController,
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline,
              ),

            if (!controller.isLogin.value) const SizedBox(height: 16),

            // Email Field
            CustomTextField(
              controller: controller.emailController,
              labelText: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone Field (Signup Only)
            if (!controller.isLogin.value)
              CustomTextField(
                controller: controller.phoneController,
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

            if (!controller.isLogin.value) const SizedBox(height: 16),

            // Password Field
            CustomTextField(
              controller: controller.passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
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
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
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

            if (!controller.isLogin.value) const SizedBox(height: 16),

            // User Type Dropdown (Signup Only)
            if (!controller.isLogin.value) _buildUserTypeDropdown(),
          ],
        ),
      ),
    ));
  }

  Widget _buildUserTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(() => DropdownButtonFormField<String>(
            value: controller.selectedUserType.value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.theme.primaryColor,
                  width: 2,
                ),
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
            ),
            onChanged: controller.onUserTypeChanged,
            items: const [
              DropdownMenuItem(
                value: 'farmer',
                child: Text('Farmer 👨‍🌾'),
              ),
              DropdownMenuItem(
                value: 'expert',
                child: Text('Agricultural Expert 🧑‍🔬'),
              ),
              DropdownMenuItem(
                value: 'company',
                child: Text('Company 🏢'),
              ),
            ],
          )),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Submit Button
        Obx(() => CustomButton(
          text: controller.isLogin.value ? 'Sign In' : 'Create Account',
          onPressed: controller.submit,
          isLoading: controller.isLoading.value,
        )),

        const SizedBox(height: 16),

        // Forgot Password (Login Only)
        Obx(() => controller.isLogin.value
            ? GestureDetector(
          onTap: controller.navigateToForgotPassword,
          child: Text(
            'Forgot Password?',
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.isLogin.value
                    ? "Don't have an account?"
                    : "Already have an account?",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: controller.toggleAuthMode,
                child: Text(
                  controller.isLogin.value ? 'Sign Up' : 'Sign In',
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
    );
  }

  Widget _buildGuestLoginSection() {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),

        const SizedBox(height: 20),

        // Guest Login Button
        OutlinedButton(
          onPressed: controller.signInAsGuest,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Get.theme.primaryColor),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Continue as Guest',
            style: TextStyle(
              color: Get.theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}