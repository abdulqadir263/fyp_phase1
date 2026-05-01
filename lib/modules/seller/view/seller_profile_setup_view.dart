import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/widgets/custom_text_field.dart';
import '../controllers/seller_auth_controller.dart';

class SellerProfileSetupView extends GetView<SellerAuthController> {
  const SellerProfileSetupView({super.key});

  static const _orange = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _orange),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Seller Profile Setup',
          style: TextStyle(color: _orange),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() => Stack(
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
                          _buildProfileCard(context),
                          const SizedBox(height: 16),
                          _buildErrorText(),
                          const SizedBox(height: 8),
                          _buildSubmitButton(),
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
            )),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
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
                  color: _orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store, color: _orange, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Store Information',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Business Name
          CustomTextField(
            controller: controller.shopNameCtrl,
            labelText: 'Business / Shop Name *',
            hintText: 'Kisaan Traders',
            prefixIcon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 14),

          // Owner Name
          CustomTextField(
            controller: controller.ownerNameCtrl,
            labelText: 'Owner Name *',
            hintText: 'Ali Khan',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 14),

          // Phone
          CustomTextField(
            controller: controller.phoneCtrl,
            labelText: 'Business Phone *',
            hintText: '03XXXXXXXXX',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
          ),
          const SizedBox(height: 14),

          // CNIC
          CustomTextField(
            controller: controller.cnicCtrl,
            labelText: 'CNIC *',
            hintText: '12345-1234567-1',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
          ),
          const SizedBox(height: 14),

          // Address
          CustomTextField(
            controller: controller.addressCtrl,
            labelText: 'Complete Address *',
            hintText: 'Shop 1, Main Market...',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
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
              child: Text(
                err,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : () => controller.submitProfile(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _orange.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Save Profile',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ));
  }
}
