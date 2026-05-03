import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/utils/app_snackbar.dart';
import '../../../modules/auth/repository/auth_repository.dart';
import '../models/appointment_model.dart';

/// FarmerAppointmentsController — real-time stream of the FARMER's own
/// consultation bookings.
///
/// Deliberately separate from BookingController so it can be mounted at any
/// route without requiring Get.arguments (an expert UserModel).
/// Firestore query: farmerUid == uid, ordered by bookedAt DESC.
///
/// NOTE: Requires a Firestore composite index:
///   Collection: appointments | Fields: farmerUid ASC, bookedAt DESC
class FarmerAppointmentsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final appointments = <AppointmentModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  StreamSubscription<QuerySnapshot>? _stream;

  @override
  void onInit() {
    super.onInit();
    _startListening();
  }

  void _startListening() {
    final uid = _authRepo.currentUser.value?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    hasError.value = false;

    _stream = _db
        .collection('appointments')
        .where('farmerUid', isEqualTo: uid)
        .orderBy('bookedAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
        appointments.assignAll(
          snap.docs
              .map((d) {
            try {
              return AppointmentModel.fromFirestore(d);
            } catch (e) {
              debugPrint(
                '[FarmerAppointmentsController] parse error ${d.id}: $e',
              );
              return null;
            }
          })
              .whereType<AppointmentModel>()
              .toList(),
        );
        isLoading.value = false;
        hasError.value = false;
      },
      onError: (e) {
        debugPrint('[FarmerAppointmentsController] stream error: $e');
        isLoading.value = false;
        hasError.value = true;

        if (e is FirebaseException && e.code == 'failed-precondition') {
          // Missing composite index: farmerUid ASC + bookedAt DESC
          errorMessage.value =
          'Database index missing. Please contact support or run:\n'
              'firebase deploy --only firestore:indexes';
          debugPrint(
            '⚠️ [FarmerAppointmentsController] Missing Firestore composite index.\n'
                'Create index for: appointments → farmerUid ASC + bookedAt DESC\n'
                'Details: ${e.message}',
          );
        } else {
          errorMessage.value = 'Failed to load appointments. Tap to retry.';
          AppSnackbar.error('Could not load appointments. Please try again.');
        }
      },
    );
  }

  /// Manual retry — cancels current stream and re-subscribes.
  void retry() {
    _stream?.cancel();
    isLoading.value = true;
    hasError.value = false;
    _startListening();
  }

  // ── Filtered getters ───────────────────────────────────────────────────────

  List<AppointmentModel> get active => appointments
      .where((a) => a.status == 'pending' || a.status == 'confirmed')
      .toList();

  List<AppointmentModel> get past => appointments
      .where((a) => a.status == 'cancelled' || a.status == 'completed')
      .toList();

  @override
  void onClose() {
    _stream?.cancel();
    super.onClose();
  }
}
