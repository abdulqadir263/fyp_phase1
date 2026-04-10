import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/field_visit_model.dart';
import '../repository/appointment_repository.dart';

/// ExpertDashboardController — Handles expert-side field visit management
/// View requests, accept/reject, complete visits with notes
class ExpertDashboardController extends GetxController {
  final AppointmentRepository _service = Get.find<AppointmentRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  // ─────────────────────────────────────────────
  // OBSERVABLE STATE
  // ─────────────────────────────────────────────

  /// Pending visit requests for this expert
  final RxList<FieldVisitModel> pendingVisits = <FieldVisitModel>[].obs;

  /// Accepted/Scheduled upcoming visits
  final RxList<FieldVisitModel> upcomingVisits = <FieldVisitModel>[].obs;

  /// Completed visits
  final RxList<FieldVisitModel> completedVisits = <FieldVisitModel>[].obs;

  /// Currently selected visit for detail view
  final Rx<FieldVisitModel?> selectedVisit = Rx<FieldVisitModel?>(null);

  /// Loading states
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;

  /// Current tab index (0=New, 1=Upcoming, 2=Completed)
  final RxInt currentTab = 0.obs;

  /// Expert notes text controller (for completing visits)
  final TextEditingController expertNotesController = TextEditingController();

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    debugPrint('[ExpertDashboardController] Initialized');
    loadAllVisits();
  }

  // ─────────────────────────────────────────────
  // DATA LOADING
  // ─────────────────────────────────────────────

  /// Load all visit categories for the expert
  Future<void> loadAllVisits() async {
    final user = _authRepository.currentUser.value;
    if (user == null) return;

    try {
      isLoading.value = true;

      // Fetch all categories in parallel
      final results = await Future.wait([
        _service.fetchExpertVisits(user.uid, statusFilter: ['pending']),
        _service.fetchExpertVisits(
          user.uid,
          statusFilter: ['accepted', 'scheduled'],
        ),
        _service.fetchExpertVisits(user.uid, statusFilter: ['completed']),
      ]);

      pendingVisits.assignAll(results[0]);
      upcomingVisits.assignAll(results[1]);
      completedVisits.assignAll(results[2]);

      debugPrint(
        '[ExpertDashboardController] Loaded: '
        '${pendingVisits.length} pending, '
        '${upcomingVisits.length} upcoming, '
        '${completedVisits.length} completed',
      );
    } catch (e) {
      debugPrint('[ExpertDashboardController] Error loading visits: $e');
      AppSnackbar.error('Unable to load visits. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // ROLE VALIDATION
  // ─────────────────────────────────────────────

  /// Ensure the current user is a valid expert before making changes
  bool _ensureExpert() {
    final user = _authRepository.currentUser.value;
    if (user == null || user.uid.isEmpty || user.userType != 'expert') {
      AppSnackbar.error('Only authenticated experts can perform this action.');
      return false;
    }
    return true;
  }

  // ─────────────────────────────────────────────
  // STATUS UPDATES
  // ─────────────────────────────────────────────

  /// Accept a pending visit request
  /// Sets status to 'accepted' and confirmedDate to preferredDate
  Future<void> acceptVisit(FieldVisitModel visit) async {
    if (!_ensureExpert()) return;
    try {
      isUpdating.value = true;
      await _service.updateVisitStatus(
        visit.id,
        newStatus: 'accepted',
        confirmedDate: visit.preferredDate,
      );
      AppSnackbar.success('Visit request accepted!');
      await loadAllVisits(); // Refresh all lists
    } catch (e) {
      debugPrint('[ExpertDashboardController] Error accepting visit: $e');
      AppSnackbar.error('Failed to accept visit. Please try again.');
    } finally {
      isUpdating.value = false;
    }
  }

  /// Reject a pending visit request
  Future<void> rejectVisit(FieldVisitModel visit) async {
    if (!_ensureExpert()) return;
    try {
      isUpdating.value = true;
      await _service.updateVisitStatus(visit.id, newStatus: 'rejected');
      AppSnackbar.success('Visit request rejected.');
      await loadAllVisits();
    } catch (e) {
      debugPrint('[ExpertDashboardController] Error rejecting visit: $e');
      AppSnackbar.error('Failed to reject visit. Please try again.');
    } finally {
      isUpdating.value = false;
    }
  }

  /// Complete a visit with expert notes
  Future<void> completeVisit(FieldVisitModel visit) async {
    if (!_ensureExpert()) return;
    final notes = expertNotesController.text.trim();
    if (notes.isEmpty) {
      AppSnackbar.warning('Please add your notes before completing.');
      return;
    }

    try {
      isUpdating.value = true;
      await _service.updateVisitStatus(
        visit.id,
        newStatus: 'completed',
        expertNotes: notes,
      );
      expertNotesController.clear();
      AppSnackbar.success('Visit marked as completed!');
      await loadAllVisits();
      Get.back(); // Return to dashboard
    } catch (e) {
      debugPrint('[ExpertDashboardController] Error completing visit: $e');
      AppSnackbar.error('Failed to complete visit. Please try again.');
    } finally {
      isUpdating.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // NAVIGATION HELPERS
  // ─────────────────────────────────────────────

  /// Open Google Maps with the farm location
  Future<void> openInMaps(FieldVisitModel visit) async {
    final url = Uri.parse(visit.googleMapsUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        AppSnackbar.error('Could not open Google Maps.');
      }
    } catch (e) {
      debugPrint('[ExpertDashboardController] Error opening maps: $e');
      AppSnackbar.error('Could not open Google Maps.');
    }
  }

  /// Select a visit for detail view
  void selectVisit(FieldVisitModel visit) {
    selectedVisit.value = visit;
  }

  @override
  void onClose() {
    expertNotesController.dispose();
    super.onClose();
  }
}
