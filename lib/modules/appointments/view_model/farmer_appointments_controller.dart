import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../modules/auth/repository/auth_repository.dart';
import '../models/appointment_model.dart';

/// FarmerAppointmentsController — real-time stream of the FARMER's own
/// consultation bookings.
///
/// Deliberately separate from BookingController so it can be mounted at any
/// route without requiring Get.arguments (an expert UserModel).
/// Firestore query: farmerUid == uid, ordered by bookedAt DESC.
class FarmerAppointmentsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final appointments = <AppointmentModel>[].obs;
  final isLoading = true.obs;

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
      },
      onError: (e) {
        debugPrint('[FarmerAppointmentsController] stream error: $e');
        isLoading.value = false;
      },
    );
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
