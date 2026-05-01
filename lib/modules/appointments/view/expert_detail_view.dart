import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/user_model.dart';
import '../../../app/themes/app_colors.dart';
import '../view_model/booking_controller.dart';

/// ExpertDetailView — Farmer browses an expert's availability and books a slot.
/// Expects Get.arguments == UserModel (the expert).
class ExpertDetailView extends GetView<BookingController> {
  const ExpertDetailView({super.key});

  static const _green = AppColors.primaryGreen;

  @override
  Widget build(BuildContext context) {
    final expert = controller.expert;
    // Safety guard — should never happen but prevents null crash
    if (expert == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: Get.back,
        ),
        title: Text(
          expert.name,
          style: const TextStyle(color: _green, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpertHeader(expert),
              const SizedBox(height: 16),
              _buildInfoCard(expert),
              const SizedBox(height: 16),
              _buildDayPicker(expert),
              const SizedBox(height: 16),
              Obx(() => controller.selectedDay.value.isNotEmpty
                  ? _buildSlotPicker(expert)
                  : const SizedBox.shrink()),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(() {
        final dayOk = controller.selectedDay.value.isNotEmpty;
        final slotOk = controller.selectedSlot.value.isNotEmpty;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: (dayOk && slotOk)
                  ? () => _showConfirmSheet(context, expert)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Book Appointment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Expert header ──────────────────────────────────────────────────────────

  Widget _buildExpertHeader(dynamic expert) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.lightGreen,
          child: Text(
            expert.name.isNotEmpty ? expert.name[0].toUpperCase() : 'E',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _green,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expert.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              if (expert.specialization != null)
                Text(
                  expert.specialization!,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[600]),
                ),
              if (expert.yearsOfExperience != null)
                Text(
                  '${expert.yearsOfExperience} yrs experience',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[500]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard(dynamic expert) {
    final fee = expert.consultationFee ?? 0;
    final mode = expert.consultationMode ?? 'Both';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.payments_outlined,
            'Consultation Fee',
            fee == 0 ? 'Free' : 'PKR $fee',
          ),
          const Divider(height: 20),
          _infoRow(
            Icons.devices_outlined,
            'Consultation Mode',
            mode,
          ),
          if (expert.location != null && expert.location!.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(
              Icons.location_on_outlined,
              'Location',
              expert.location!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _green),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Step 1: Day picker ─────────────────────────────────────────────────────

  Widget _buildDayPicker(UserModel expert) {
    final availableDays = expert.availableDays ?? [];
    final totalSlots = (expert.availableSlots ?? []).length;

    if (availableDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text('This expert has not set available days yet.'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1 — Select a Day',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        // Wrap is inside Obx so it reacts to bookedSlots stream updates
        Obx(() {
          // For each day we check how many of this expert's slots are booked
          // on THAT day by re-querying the live bookedSlots list.
          // Note: bookedSlots reflects the currently-selected day's stream.
          // For multi-day saturation we rely on per-day load after selection.
          final selectedDay = controller.selectedDay.value;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableDays.map((day) {
              final isSelected = selectedDay == day;
              // Fully booked: only known when this day IS selected
              // (stream only runs for the selected day to save reads)
              final isFullyBooked = isSelected &&
                  totalSlots > 0 &&
                  controller.bookedSlots.length >= totalSlots;

              return GestureDetector(
                onTap: isFullyBooked ? null : () => controller.selectDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFullyBooked
                        ? Colors.grey.shade200
                        : isSelected
                            ? _green
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFullyBooked
                          ? Colors.grey.shade300
                          : isSelected
                              ? _green
                              : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          color: isFullyBooked
                              ? Colors.grey
                              : isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      if (isFullyBooked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Full',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ── Step 2: Slot picker ────────────────────────────────────────────────────

  Widget _buildSlotPicker(UserModel expert) {
    final availableSlots = expert.availableSlots ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2 — Select a Time Slot',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Obx(() {
          if (controller.isLoadingSlots.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (availableSlots.isEmpty) {
            return const Text('No time slots defined for this expert.');
          }
          return Column(
            children: availableSlots.map((slot) {
              final isBooked = controller.bookedSlots.contains(slot);
              final isSelected = controller.selectedSlot.value == slot;
              return GestureDetector(
                onTap: isBooked ? null : () => controller.selectSlot(slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isBooked
                        ? Colors.grey.shade100
                        : isSelected
                            ? _green.withValues(alpha: 0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBooked
                          ? Colors.grey.shade300
                          : isSelected
                              ? _green
                              : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isBooked
                            ? Icons.block
                            : isSelected
                                ? Icons.check_circle
                                : Icons.access_time,
                        color: isBooked
                            ? Colors.grey
                            : isSelected
                                ? _green
                                : Colors.grey[400],
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 14,
                            color: isBooked
                                ? Colors.grey
                                : isSelected
                                    ? _green
                                    : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isBooked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Booked',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ── Confirmation bottom sheet ──────────────────────────────────────────────

  void _showConfirmSheet(BuildContext context, UserModel expert) {
    final fee = expert.consultationFee ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Booking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _sheetRow('Expert', expert.name),
            _sheetRow('Day', controller.selectedDay.value),
            _sheetRow('Time', controller.selectedSlot.value),
            _sheetRow('Fee', fee == 0 ? 'Free' : 'PKR $fee'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => ElevatedButton(
                        onPressed: controller.isBooking.value
                            ? null
                            : controller.confirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: controller.isBooking.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirm Booking',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
