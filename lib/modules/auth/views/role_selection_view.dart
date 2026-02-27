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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ========== HEADER SECTION ==========
              _buildHeader(),

              const SizedBox(height: 48),

              // ========== ROLE CARDS ==========
              Expanded(
                child: _buildRoleCards(),
              ),

              // ========== GUEST OPTION ==========
              _buildGuestOption(),

              const SizedBox(height: 20),
            ],
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
          'Select Your Role',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppConstants.darkGreen,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Choose how you want to use Aasaan Kisaan',
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
          title: 'Farmer',
          description: 'I grow crops and manage a farm',
          icon: Icons.grass,
          color: AppConstants.primaryGreen,
        ),

        const SizedBox(height: 16),

        // Expert Card
        _buildRoleCard(
          role: 'expert',
          title: 'Expert',
          description: 'I provide agricultural advice',
          icon: Icons.school,
          color: Colors.blue[700]!,
        ),

        const SizedBox(height: 16),

        // Company/Seller Card
        _buildRoleCard(
          role: 'company',
          title: 'Company (Seller)',
          description: 'I sell agricultural products',
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
            'Continue as Guest',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              decoration: TextDecoration.underline,
            ),
          ),
        ),

        Text(
          'Limited features available',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}



