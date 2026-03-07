import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../../../core/constants/app_constants.dart';

/// RoleSelectionView - First screen after signup
/// Allows user to select their role: Farmer, Expert, or Company (Seller)
/// Also provides Guest access option
class RoleSelectionView extends GetView<OnboardingController> {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom - 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // ========== HEADER SECTION ==========
              _buildHeader(),

              const SizedBox(height: 48),

              // ========== ROLE CARDS ==========
              _buildRoleCards(),

              const SizedBox(height: 24),

              // ========== GUEST OPTION ==========
              _buildGuestOption(),

              const SizedBox(height: 20),
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// Build the header with app icon and title
  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.lightGreen.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.agriculture,
            size: 60,
            color: AppConstants.primaryGreen,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'select_your_role'.tr,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppConstants.darkGreen,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'choose_how_use'.tr,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build the role selection cards
  Widget _buildRoleCards() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Farmer Card
        _buildRoleCard(
          role: 'farmer',
          title: 'farmer'.tr,
          description: 'farmer_desc'.tr,
          icon: Icons.grass,
          color: AppConstants.primaryGreen,
        ),

        const SizedBox(height: 16),

        // Expert Card
        _buildRoleCard(
          role: 'expert',
          title: 'expert'.tr,
          description: 'expert_desc'.tr,
          icon: Icons.school,
          color: Colors.blue[700]!,
        ),

        const SizedBox(height: 16),

        // Company/Seller Card
        _buildRoleCard(
          role: 'company',
          title: 'company_seller'.tr,
          description: 'company_desc'.tr,
          icon: Icons.store,
          color: Colors.orange[700]!,
        ),
      ],
    );
  }

  /// Build individual role card
  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Obx(() {
      final isSelected = controller.selectedRole.value == role;

      return InkWell(
        onTap: () => controller.selectRole(role),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: isSelected ? color : Colors.grey[400],
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Build the guest access option at bottom
  Widget _buildGuestOption() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),

        TextButton(
          onPressed: controller.continueAsGuest,
          child: Text(
            'continue_as_guest'.tr,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              decoration: TextDecoration.underline,
            ),
          ),
        ),

        Text(
          'limited_features'.tr,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}



