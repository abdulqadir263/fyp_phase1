import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';

// Login/Signup ka combined screen
class LoginView extends GetView<AuthController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ya Title
                Icon(
                  Icons.agriculture,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'FarmAssist',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 40),

                // Form
                Obx(() => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildForm(),
                )),

                const SizedBox(height: 20),

                // Submit Button
                Obx(() => CustomButton(
                  text: controller.isLogin.value ? 'Login' : 'Sign Up',
                  onPressed: controller.submit,
                  isLoading: controller.isLoading.value,
                )),

                const SizedBox(height: 20),

                // ✅ FIXED: Forgot Password Button (sirf login mode mein)
                Obx(() => controller.isLogin.value
                    ? Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: controller.forgotPassword,
                    child: Text('Forgot Password?'),
                  ),
                )
                    : SizedBox.shrink()),

                // Toggle Button
                TextButton(
                  onPressed: controller.toggleAuthMode,
                  child: Obx(() => Text(
                    controller.isLogin.value
                        ? 'Don\'t have an account? Sign Up'
                        : 'Already have an account? Login',
                  )),
                ),

                const SizedBox(height: 30),

                // Divider and Guest Login Section
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                // Continue as Guest Button
                OutlinedButton(
                  onPressed: controller.signInAsGuest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Form build karna (login/signup ke hisaab se fields change hon)
  Widget _buildForm() {
    return Form(
      key: ValueKey(controller.isLogin.value ? 'login' : 'signup'),
      child: Column(
        children: [
          // Name field (sirf signup mein dikhega)
          if (!controller.isLogin.value) ...[
            CustomTextField(
              controller: controller.nameController,
              labelText: 'Full Name',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          CustomTextField(
            controller: controller.emailController,
            labelText: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Phone field (sirf signup mein dikhega)
          if (!controller.isLogin.value) ...[
            CustomTextField(
              controller: controller.phoneController,
              labelText: 'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // User Type Dropdown (sirf signup mein dikhega)
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedUserType.value,
              decoration: const InputDecoration(
                labelText: 'I am a...',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value != null) controller.selectedUserType.value = value;
              },
              items: const [
                DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                DropdownMenuItem(value: 'expert', child: Text('Agricultural Expert')),
                DropdownMenuItem(value: 'company', child: Text('Company')),
              ],
            )),
            const SizedBox(height: 16),
          ],

          // Password field
          CustomTextField(
            controller: controller.passwordController,
            labelText: 'Password',
            prefixIcon: Icons.lock,
            obscureText: true,
          ),
        ],
      ),
    );
  }
}