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
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.sizeOf(context).height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildRoleCards(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Obx(
                () => controller.isLoading.value
                    ? Container(
                        color: Colors.white.withValues(alpha: 0.7),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the header with app icon and title
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Icon
          Container(
            padding: const EdgeInsets.all(18),
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
              fontSize: 30,
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
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'You can update details after profile completion.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
          title: 'Seller',
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
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
                child: Icon(icon, size: 32, color: color),
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
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
}
