import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../app/widgets/custom_text_field.dart';

// Ye file optional hai, kyunki main ne combined login/signup view banai hai
// Agar aap ko alag signup view chahiye to ye use kar sakte hain
class SignupView extends GetView<AuthController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('create_account'.tr), centerTitle: true),
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
                  'create_account'.tr,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 40),

                // Form
                Form(
                  child: Column(
                    children: [
                      // Name field
                      CustomTextField(
                        controller: controller.nameController,
                        labelText: 'full_name'.tr,
                        prefixIcon: Icons.person,
                      ),
                      const SizedBox(height: 16),

                      // Email field
                      CustomTextField(
                        controller: controller.emailController,
                        labelText: 'email'.tr,
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Phone field
                      CustomTextField(
                        controller: controller.phoneController,
                        labelText: 'phone_number'.tr,
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Role selection removed - now handled on separate RoleSelectionView screen

                      // Password field
                      CustomTextField(
                        controller: controller.passwordController,
                        labelText: 'password'.tr,
                        prefixIcon: Icons.lock,
                        obscureText: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Submit Button
                Obx(
                  () => CustomButton(
                    text: 'sign_up'.tr,
                    onPressed: controller.submit,
                    isLoading: controller.isLoading.value,
                  ),
                ),

                const SizedBox(height: 20),

                // Login link
                TextButton(
                  onPressed: controller.closeCurrentScreen,
                  child: Text('already_have_account_login'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
