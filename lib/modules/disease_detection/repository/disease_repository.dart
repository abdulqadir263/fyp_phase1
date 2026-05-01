import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/disease_history_record.dart';

/// Firestore persistence layer for disease detection history.
///
/// Collection: `diseaseDetectionHistory`
/// Each document is owned by a single [userId].
class DiseaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'detectionHistory';

  /// Save a detection result to Firestore and return the new document ID.
  Future<String> saveRecord(DiseaseHistoryRecord record) async {
    try {
      final docRef = await _firestore
          .collection('farmers')
          .doc(record.userId)
          .collection(_collection)
          .add(record.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save disease record: $e');
    }
  }

  /// Fetch the last 50 records for [userId], ordered newest-first.
  Future<List<DiseaseHistoryRecord>> fetchHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('farmers')
          .doc(userId)
          .collection(_collection)
          .get();

      final records = snapshot.docs
          .map((doc) =>
              DiseaseHistoryRecord.fromJson(doc.data(), docId: doc.id))
          .toList();
          
      // Sort newest-first locally to avoid Firestore composite index requirement
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Limit to 50 records
      return records.take(50).toList();
    } catch (e) {
      throw Exception('Failed to fetch disease history: $e');
    }
  }
}
