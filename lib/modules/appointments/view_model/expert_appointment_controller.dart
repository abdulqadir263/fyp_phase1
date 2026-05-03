import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/utils/app_snackbar.dart';
import '../../../modules/auth/repository/auth_repository.dart';
import '../models/appointment_model.dart';

/// ExpertAppointmentController — real-time stream of the expert's
/// consultation appointments (NOT field visits).
///
/// Uses TWO streams:
///  • _activeStream  — pending + confirmed, ordered by bookedAt ASC
///                     (what the expert sees and acts on in real-time)
///  • _historyStream — cancelled + completed, ordered by bookedAt DESC
///                     (for the "Past" tab)
///
/// NOTE: Requires two Firestore composite indexes:
///   1. appointments → expertUid ASC, status ASC, bookedAt ASC
///   2. appointments → expertUid ASC, status ASC, bookedAt DESC
///
/// All subscriptions are cancelled in onClose().
class ExpertAppointmentController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final activeAppointments = <AppointmentModel>[].obs;
  final pastAppointments = <AppointmentModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  StreamSubscription<QuerySnapshot>? _activeStream;
  StreamSubscription<QuerySnapshot>? _historyStream;

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

    // ── Active appointments stream (pending + confirmed) ───────────────────
    _activeStream = _db
        .collection('appointments')
        .where('expertUid', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('bookedAt', descending: false) // chronological for expert
        .snapshots()
        .listen(
          (snap) {
        activeAppointments.assignAll(_parseSnap(snap));
        isLoading.value = false;
        hasError.value = false;
      },
      onError: (e) {
        debugPrint('[ExpertAppointmentController] active stream error: $e');
        isLoading.value = false;
        _handleStreamError(e,
            indexHint: 'appointments → expertUid ASC + status ASC + bookedAt ASC');
      },
    );

    // ── History stream (cancelled + completed) ─────────────────────────────
    _historyStream = _db
        .collection('appointments')
        .where('expertUid', isEqualTo: uid)
        .where('status', whereIn: ['cancelled', 'completed'])
        .orderBy('bookedAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
        pastAppointments.assignAll(_parseSnap(snap));
      },
      onError: (e) {
        debugPrint('[ExpertAppointmentController] history stream error: $e');
        _handleStreamError(e,
            indexHint: 'appointments → expertUid ASC + status ASC + bookedAt DESC');
      },
    );
  }

  void _handleStreamError(Object e, {required String indexHint}) {
    hasError.value = true;
    if (e is FirebaseException && e.code == 'failed-precondition') {
      errorMessage.value =
      'Database index missing. Please contact support or run:\n'
          'firebase deploy --only firestore:indexes';
      debugPrint(
        '⚠️ [ExpertAppointmentController] Missing Firestore composite index.\n'
            'Create index for: $indexHint\n'
            'Details: ${(e as FirebaseException).message}',
      );
    } else {
      errorMessage.value = 'Failed to load appointments. Tap to retry.';
      AppSnackbar.error('Could not load appointments. Please try again.');
    }
  }

  /// Manual retry — cancels streams and re-subscribes.
  void retry() {
    _activeStream?.cancel();
    _historyStream?.cancel();
    isLoading.value = true;
    hasError.value = false;
    activeAppointments.clear();
    pastAppointments.clear();
    _startListening();
  }

  List<AppointmentModel> _parseSnap(QuerySnapshot snap) {
    return snap.docs
        .map((d) {
      try {
        return AppointmentModel.fromFirestore(d);
      } catch (e) {
        debugPrint(
          '[ExpertAppointmentController] parse error ${d.id}: $e',
        );
        return null;
      }
    })
        .whereType<AppointmentModel>()
        .toList();
  }

  // ── Filtered getters ───────────────────────────────────────────────────────

  List<AppointmentModel> get pending =>
      activeAppointments.where((a) => a.status == 'pending').toList();

  List<AppointmentModel> get confirmed =>
      activeAppointments.where((a) => a.status == 'confirmed').toList();

  List<AppointmentModel> get done => pastAppointments.toList();

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> confirmAppointment(String id) async {
    try {
      await _db
          .collection('appointments')
          .doc(id)
          .update({'status': 'confirmed'});
      AppSnackbar.success('Appointment confirmed.');
    } on FirebaseException catch (e) {
      debugPrint('[ExpertAppointmentController] confirmAppointment FirebaseException: ${e.code}');
      AppSnackbar.error('Network error. Please try again.');
    } catch (e) {
      debugPrint('[ExpertAppointmentController] confirmAppointment error: $e');
      AppSnackbar.error('Failed to confirm. Please try again.');
    }
  }

  Future<void> cancelAppointment(String id) async {
    try {
      await _db
          .collection('appointments')
          .doc(id)
          .update({'status': 'cancelled'});
      AppSnackbar.success('Appointment cancelled — slot is now open again.');
    } on FirebaseException catch (e) {
      debugPrint('[ExpertAppointmentController] cancelAppointment FirebaseException: ${e.code}');
      AppSnackbar.error('Network error. Please try again.');
    } catch (e) {
      debugPrint('[ExpertAppointmentController] cancelAppointment error: $e');
      AppSnackbar.error('Failed to cancel. Please try again.');
    }
  }

  Future<void> completeAppointment(String id) async {
    try {
      await _db
          .collection('appointments')
          .doc(id)
          .update({'status': 'completed'});
      AppSnackbar.success('Appointment marked as completed.');
    } on FirebaseException catch (e) {
      debugPrint('[ExpertAppointmentController] completeAppointment FirebaseException: ${e.code}');
      AppSnackbar.error('Network error. Please try again.');
    } catch (e) {
      debugPrint('[ExpertAppointmentController] completeAppointment error: $e');
      AppSnackbar.error('Failed to update. Please try again.');
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _activeStream?.cancel();
    _historyStream?.cancel();
    super.onClose();
  }
}
