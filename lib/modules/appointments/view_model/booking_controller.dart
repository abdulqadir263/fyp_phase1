import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/data/models/user_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/utils/app_snackbar.dart';
import '../../../modules/auth/repository/auth_repository.dart';
import '../models/appointment_model.dart';

/// BookingController — manages the farmer-side slot booking flow for
/// ExpertDetailView ONLY.
///
/// Key design decisions:
/// • expert is loaded from Get.arguments on every onInit() call.
/// • bookedSlots is backed by a real-time Firestore STREAM so concurrent
///   bookings from other farmers are reflected instantly without a refresh.
/// • Switching days cancels the previous stream and starts a new one —
///   no bleed between days.
/// • confirmBooking() performs a server-side re-check BEFORE writing to
///   guard against simultaneous bookings (race-condition safety).
/// • All StreamSubscriptions are cancelled in onClose().
class BookingController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  // ── Expert, set from Get.arguments on every navigation ────────────────────
  UserModel? expert;

  // ── UI state ──────────────────────────────────────────────────────────────
  final selectedDay = ''.obs;
  final selectedSlot = ''.obs;

  /// Slots that are already pending/confirmed for the selected day.
  final bookedSlots = <String>[].obs;

  final isLoadingSlots = false.obs;
  final isBooking = false.obs;

  /// The just-created appointment — passed to AppointmentConfirmationView.
  final Rx<AppointmentModel?> lastAppointment = Rx<AppointmentModel?>(null);

  // ── Stream subscription ───────────────────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _slotStream;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is UserModel) {
      expert = args;
    }
    // Reset per-session state in case controller is reused (fenix: true)
    selectedDay.value = '';
    selectedSlot.value = '';
    bookedSlots.clear();
  }

  // ── Day selection ─────────────────────────────────────────────────────────

  /// Called when the farmer taps a day chip.
  /// Cancels the previous slot stream, resets slot selection, starts fresh.
  void selectDay(String day) {
    selectedDay.value = day;
    selectedSlot.value = '';  // clear stale slot selection
    bookedSlots.clear();      // clear stale booked list immediately
    _startSlotStream(day);
  }

  // ── Slot stream ───────────────────────────────────────────────────────────

  /// Starts a Firestore STREAM for the given day.
  /// Cancels any previously active stream first (handles day switching).
  void _startSlotStream(String day) {
    final uid = expert?.uid;
    if (uid == null) return;

    isLoadingSlots.value = true;
    _slotStream?.cancel();

    _slotStream = _db
        .collection('appointments')
        .where('expertUid', isEqualTo: uid)
        .where('day', isEqualTo: day)
        .where('status', whereIn: ['pending', 'confirmed'])
        .snapshots()
        .listen(
      (snap) {
        final booked = snap.docs
            .map((d) => (d.data()['slot'] as String?) ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();

        bookedSlots.assignAll(booked.toList());

        // If the currently selected slot just got taken, deselect + warn
        if (selectedSlot.value.isNotEmpty &&
            booked.contains(selectedSlot.value)) {
          selectedSlot.value = '';
          AppSnackbar.warning(
            'Your selected slot was just taken. Please pick another.',
          );
        }

        isLoadingSlots.value = false;
      },
      onError: (e) {
        debugPrint('[BookingController] slot stream error: $e');
        isLoadingSlots.value = false;
      },
    );
  }

  // ── Slot selection ────────────────────────────────────────────────────────

  void selectSlot(String slot) {
    if (bookedSlots.contains(slot)) {
      AppSnackbar.error('This slot is already booked. Please pick another.');
      return;
    }
    selectedSlot.value = slot;
  }

  // ── Confirm booking (race-condition–safe) ─────────────────────────────────

  Future<void> confirmBooking() async {
    final exp = expert;
    if (exp == null) {
      AppSnackbar.error('Expert data missing. Please go back and try again.');
      return;
    }

    final farmer = _authRepo.currentUser.value;
    if (farmer == null) {
      AppSnackbar.error('You must be signed in to book.');
      return;
    }
    if (selectedDay.value.isEmpty || selectedSlot.value.isEmpty) {
      AppSnackbar.warning('Please select a day and a time slot.');
      return;
    }

    isBooking.value = true;
    try {
      // ── Race-condition guard: server-side re-check ────────────────────────
      final existing = await _db
          .collection('appointments')
          .where('expertUid', isEqualTo: exp.uid)
          .where('day', isEqualTo: selectedDay.value)
          .where('slot', isEqualTo: selectedSlot.value)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      if (existing.docs.isNotEmpty) {
        AppSnackbar.error(
          'This slot was just taken. Please pick another.',
        );
        // The live stream will automatically update bookedSlots
        selectedSlot.value = '';
        return;
      }

      // ── Write the appointment ─────────────────────────────────────────────
      final appointment = AppointmentModel(
        id: '',
        expertUid: exp.uid,
        farmerUid: farmer.uid,
        farmerName: farmer.name,
        expertName: exp.name,
        day: selectedDay.value,
        slot: selectedSlot.value,
        status: 'pending',
        bookedAt: DateTime.now(),
        consultationMode: exp.consultationMode ?? 'Both',
        fee: exp.consultationFee ?? 0,
      );

      final ref = await _db
          .collection('appointments')
          .add(appointment.toMap());

      lastAppointment.value = AppointmentModel(
        id: ref.id,
        expertUid: appointment.expertUid,
        farmerUid: appointment.farmerUid,
        farmerName: appointment.farmerName,
        expertName: appointment.expertName,
        day: appointment.day,
        slot: appointment.slot,
        status: appointment.status,
        bookedAt: appointment.bookedAt,
        consultationMode: appointment.consultationMode,
        fee: appointment.fee,
      );

      Get.back(); // close confirm bottom sheet
      Get.toNamed(
        AppRoutes.APPOINTMENT_CONFIRMATION,
        arguments: lastAppointment.value,
      );
    } on FirebaseException catch (e) {
      debugPrint(
          '[BookingController] FirebaseException: ${e.code} ${e.message}');
      AppSnackbar.error(
        'Network error. Please check your connection and try again.',
      );
      // Do NOT navigate — leave the sheet open so farmer can retry
    } catch (e) {
      debugPrint('[BookingController] confirmBooking error: $e');
      AppSnackbar.error('Booking failed. Please try again.');
      // Do NOT navigate
    } finally {
      isBooking.value = false;
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _slotStream?.cancel();
    super.onClose();
  }
}
