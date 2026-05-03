import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_colors.dart';
import '../models/appointment_model.dart';

/// AppointmentConfirmationView — shown after a booking is confirmed.
/// Receives an AppointmentModel via Get.arguments.
class AppointmentConfirmationView extends StatelessWidget {
  const AppointmentConfirmationView({super.key});

  static const _green = AppColors.primaryGreen;

  @override
  Widget build(BuildContext context) {
    final appt = Get.arguments as AppointmentModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: _green,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment has been sent to the expert.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Details card
              Container(
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
                    _row('Expert', appt.expertName),
                    _divider(),
                    _row('Day', appt.day),
                    _divider(),
                    _row('Time', appt.slot),
                    _divider(),
                    _row('Mode', appt.consultationMode),
                    _divider(),
                    _row('Fee',
                        appt.fee == 0 ? 'Free' : 'PKR ${appt.fee}'),
                    _divider(),
                    _row('Status', 'Pending Expert Confirmation'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // View My Appointments button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Get.offAllNamed(AppRoutes.FARMER_APPOINTMENTS),
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  label: const Text(
                    'View My Appointments',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back to Home (secondary)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.HOME),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Back to Home',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100);
}
