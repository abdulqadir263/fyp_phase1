import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../farmer/farmer_session_controller.dart';
import '../repository/auth_repository.dart';

/// RoleSelectionView - First screen after welcome
/// Users select their desired role and are navigated to the role-specific signup.
class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
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
                const SizedBox(height: 24),
                _buildRoleCards(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.lightGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture,
              size: 48,
              color: AppConstants.primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'select_your_role'.tr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'choose_how_use'.tr,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCards() {
    return Column(
      children: [
        _buildRoleCard(
          title: 'farmer'.tr,
          description: 'farmer_desc'.tr,
          icon: Icons.grass,
          color: AppConstants.primaryGreen,
          onTap: () {
            // MIGRATION: link to phone credential when Firebase Blaze plan is enabled
            // await FirebaseAuth.instance.currentUser?.linkWithCredential(phoneCredential)
            final controller = Get.put(FarmerSessionController());
            controller.signInAnonymously();
          },
        ),
        const SizedBox(height: 12),
        _buildRoleCard(
          title: 'expert'.tr,
          description: 'expert_desc'.tr,
          icon: Icons.school,
          color: const Color(0xFF1565C0),
          onTap: () {
            Get.find<AuthRepository>().setRole('expert');
            Get.toNamed(AppRoutes.EXPERT_AUTH);
          },
        ),
        const SizedBox(height: 12),
        _buildRoleCard(
          title: 'Seller',
          description: 'company_desc'.tr,
          icon: Icons.store,
          color: const Color(0xFFE65100),
          onTap: () {
            Get.find<AuthRepository>().setRole('seller');
            Get.toNamed(AppRoutes.SELLER_AUTH);
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 22,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
