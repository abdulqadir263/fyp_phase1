import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/field_visit_model.dart';
import '../../../app/data/models/user_model.dart';

/// AppointmentService — Handles all Firestore operations for field visits
/// Keeps Firebase logic separate from controllers (Clean Architecture)
class AppointmentService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore collection name
  static const String _collectionName = 'fieldVisits';

  CollectionReference get _visitsCollection =>
      _firestore.collection(_collectionName);

  // ─────────────────────────────────────────────
  // EXPERT QUERIES
  // ─────────────────────────────────────────────

  /// Fetch all experts (users with userType == 'expert')
  /// Used by farmers to browse available experts
  Future<List<UserModel>> fetchExperts() async {
    try {
      debugPrint('[AppointmentService] Fetching experts...');
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'expert')
          .where('isProfileComplete', isEqualTo: true)
          .get();

      final experts = snapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .toList();

      debugPrint('[AppointmentService] Found ${experts.length} experts');
      return experts;
    } catch (e) {
      debugPrint('[AppointmentService] Error fetching experts: $e');
      rethrow;
    }
  }

  /// Fetch a single expert by UID
  Future<UserModel?> fetchExpertById(String expertId) async {
    try {
      final doc = await _firestore.collection('users').doc(expertId).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('[AppointmentService] Error fetching expert: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // FIELD VISIT CRUD
  // ─────────────────────────────────────────────

  /// Create a new field visit request
  /// Called by farmer when requesting a visit
  Future<String> createVisitRequest(FieldVisitModel visit) async {
    try {
      debugPrint('[AppointmentService] Creating visit request...');
      final docRef = await _visitsCollection.add(visit.toDocument());
      debugPrint('[AppointmentService] Visit created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[AppointmentService] Error creating visit: $e');
      rethrow;
    }
  }

  /// Fetch all visits for a specific farmer
  /// Ordered by creation date (newest first)
  /// Requires Firestore composite index: farmerId (ASC) + createdAt (DESC)
  Future<List<FieldVisitModel>> fetchFarmerVisits(String farmerId) async {
    try {
      debugPrint('[AppointmentService] Fetching visits for farmer: $farmerId');
      final snapshot = await _visitsCollection
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('createdAt', descending: true)
          .get();

      final visits = snapshot.docs
          .map((doc) => FieldVisitModel.fromDocument(doc))
          .toList();

      debugPrint('[AppointmentService] Found ${visits.length} farmer visits');
      return visits;
    } on FirebaseException catch (e) {
      // Handle missing Firestore composite index gracefully
      if (e.code == 'failed-precondition') {
        debugPrint(
          '⚠️ [AppointmentService] Missing Firestore index for '
          'farmerId + createdAt query. '
          'Deploy indexes: firebase deploy --only firestore:indexes\n'
          'Details: ${e.message}',
        );
        // Return empty list — do NOT crash the UI
        return [];
      }
      debugPrint('[AppointmentService] FirebaseException fetching farmer visits: '
          '${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AppointmentService] Error fetching farmer visits: $e');
      rethrow;
    }
  }

  /// Fetch visits assigned to a specific expert, filtered by status list
  /// Used by expert dashboard tabs
  /// Requires Firestore composite index: expertId (ASC) + status (ASC) + createdAt (DESC)
  Future<List<FieldVisitModel>> fetchExpertVisits(
    String expertId, {
    List<String>? statusFilter,
  }) async {
    try {
      debugPrint(
          '[AppointmentService] Fetching visits for expert: $expertId, '
          'statusFilter: $statusFilter');

      Query query = _visitsCollection.where('expertId', isEqualTo: expertId);

      if (statusFilter != null && statusFilter.isNotEmpty) {
        // Firestore whereIn supports up to 10 values
        query = query.where('status', whereIn: statusFilter);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      final visits = snapshot.docs
          .map((doc) => FieldVisitModel.fromDocument(doc))
          .toList();

      debugPrint('[AppointmentService] Found ${visits.length} expert visits');
      return visits;
    } on FirebaseException catch (e) {
      // Handle missing Firestore composite index gracefully
      if (e.code == 'failed-precondition') {
        debugPrint(
          '⚠️ [AppointmentService] Missing Firestore index for '
          'expertId + status + createdAt query. '
          'Deploy indexes: firebase deploy --only firestore:indexes\n'
          'Details: ${e.message}',
        );
        // Return empty list — do NOT crash the UI
        return [];
      }
      debugPrint('[AppointmentService] FirebaseException fetching expert visits: '
          '${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AppointmentService] Error fetching expert visits: $e');
      rethrow;
    }
  }

  /// Fetch a single visit by ID
  Future<FieldVisitModel?> fetchVisitById(String visitId) async {
    try {
      final doc = await _visitsCollection.doc(visitId).get();
      if (doc.exists) {
        return FieldVisitModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('[AppointmentService] Error fetching visit: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // STATUS UPDATES
  // ─────────────────────────────────────────────

  /// Update visit status (used by expert to accept/reject/complete)
  /// Only expert assigned to the visit should call this
  Future<void> updateVisitStatus(
    String visitId, {
    required String newStatus,
    DateTime? confirmedDate,
    String? expertNotes,
  }) async {
    try {
      debugPrint(
          '[AppointmentService] Updating visit $visitId → $newStatus');

      final Map<String, dynamic> updateData = {
        'status': newStatus,
      };

      if (confirmedDate != null) {
        updateData['confirmedDate'] = Timestamp.fromDate(confirmedDate);
      }

      if (expertNotes != null) {
        updateData['expertNotes'] = expertNotes;
      }

      await _visitsCollection.doc(visitId).update(updateData);
      debugPrint('[AppointmentService] Visit status updated successfully');
    } catch (e) {
      debugPrint('[AppointmentService] Error updating visit status: $e');
      rethrow;
    }
  }

  /// Cancel a visit (used by farmer, only if status == pending)
  Future<void> cancelVisit(String visitId) async {
    try {
      debugPrint('[AppointmentService] Cancelling visit: $visitId');

      // Verify current status before cancelling
      final doc = await _visitsCollection.doc(visitId).get();
      if (!doc.exists) throw 'Visit not found';

      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] != 'pending') {
        throw 'Only pending visits can be cancelled';
      }

      await _visitsCollection.doc(visitId).update({'status': 'cancelled'});
      debugPrint('[AppointmentService] Visit cancelled successfully');
    } catch (e) {
      debugPrint('[AppointmentService] Error cancelling visit: $e');
      rethrow;
    }
  }
}

