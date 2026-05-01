import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/widgets/custom_text_field.dart';
import '../controllers/expert_auth_controller.dart';

class ExpertProfileSetupView extends GetView<ExpertAuthController> {
  const ExpertProfileSetupView({super.key});

  static const _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _blue),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Expert Profile Setup',
          style: TextStyle(color: _blue),
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
                  color: _blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: _blue, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Complete your Profile',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Name
          CustomTextField(
            controller: controller.nameCtrl,
            labelText: 'Full Name *',
            hintText: 'Dr. Ahmad Khan',
            prefixIcon: Icons.person_outline,
            validator: controller.validateName,
          ),
          const SizedBox(height: 14),

          // Specialization dropdown
          _buildSpecializationDropdown(),
          const SizedBox(height: 14),

          // Years experience
          CustomTextField(
            controller: controller.yearsExpCtrl,
            labelText: 'Years of Experience *',
            hintText: 'e.g. 5',
            prefixIcon: Icons.work_history_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: controller.validateYears,
          ),
          const SizedBox(height: 14),

          // Phone (optional, contact only)
          CustomTextField(
            controller: controller.phoneCtrl,
            labelText: 'Phone (optional)',
            hintText: '03XXXXXXXXX',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
          ),
          const SizedBox(height: 14),

          // Location
          CustomTextField(
            controller: controller.locationCtrl,
            labelText: 'Location',
            hintText: 'City, Province',
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 14),

          // Certifications
          CustomTextField(
            controller: controller.certificationsCtrl,
            labelText: 'Certifications',
            hintText: 'e.g. MSc Agriculture, PARC certified',
            prefixIcon: Icons.card_membership_outlined,
          ),
          const SizedBox(height: 14),

          // Bio
          CustomTextField(
            controller: controller.bioCtrl,
            labelText: 'Short Bio',
            hintText: 'Briefly describe your expertise…',
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 14),

          // Availability toggle
          _buildAvailabilityToggle(),
          const SizedBox(height: 14),

          // Available Days
          _buildAvailableDays(),
          const SizedBox(height: 14),

          // Time Slots
          _buildTimeSlots(),
          const SizedBox(height: 14),

          // Consultation Fee
          CustomTextField(
            controller: controller.consultationFeeCtrl,
            labelText: 'Consultation Fee (PKR)',
            hintText: 'Enter 0 for free consultation',
            prefixIcon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),

          // Consultation Mode
          _buildConsultationMode(),
        ],
      ),
    );
  }

  Widget _buildSpecializationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialization *',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700]),
        ),
        const SizedBox(height: 6),
        Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedSpecialization.value.isEmpty
                  ? null
                  : controller.selectedSpecialization.value,
              decoration: _dropdownDec(Icons.workspace_premium_outlined),
              hint: const Text('Select specialization'),
              isExpanded: true,
              items: ExpertAuthController.specializations
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.selectedSpecialization.value = v;
              },
            )),
      ],
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: _blue, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available for Consultations',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text('Let farmers book field visits',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Obx(() => Switch(
                value: controller.isAvailableForConsultation.value,
                onChanged: (v) =>
                    controller.isAvailableForConsultation.value = v,
                activeColor: _blue,
              )),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
        const SizedBox(height: 2),
        Text(sub,
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAvailableDays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          'Available Days *',
          'Select days you are available for consultations',
        ),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ExpertAuthController.weekDays.map((day) {
                final selected = controller.selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    if (selected) {
                      controller.selectedDays.remove(day);
                    } else {
                      controller.selectedDays.add(day);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _blue : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? _blue : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? Colors.white : Colors.grey[700],
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          'Available Time Slots *',
          'Select your consultation time windows',
        ),
        Obx(() => Column(
              children: ExpertAuthController.timeSlots.map((slot) {
                final selected = controller.selectedSlots.contains(slot);
                return GestureDetector(
                  onTap: () {
                    if (selected) {
                      controller.selectedSlots.remove(slot);
                    } else {
                      controller.selectedSlots.add(slot);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? _blue.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? _blue : Colors.grey.shade300,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected ? _blue : Colors.grey[400],
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          slot,
                          style: TextStyle(
                            fontSize: 14,
                            color: selected ? _blue : Colors.grey[700],
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildConsultationMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Consultation Mode', ''),
        Obx(() => Row(
              children: ExpertAuthController.consultationModes.map((mode) {
                final selected =
                    controller.selectedConsultationMode.value == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.selectedConsultationMode.value = mode,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? _blue : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? _blue : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        mode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? Colors.white : Colors.grey[700],
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            )),
      ],
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
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _blue.withValues(alpha: 0.5),
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

  InputDecoration _dropdownDec(IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
