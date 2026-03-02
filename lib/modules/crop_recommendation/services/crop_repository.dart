import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_model.dart';
import '../models/recommendation_model.dart';

/// Repository handling all Firestore operations for crop recommendation.
class CropRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cropsCollection = 'crops';
  static const String _recommendationsCollection = 'cropRecommendations';

  /// Fetch all crop documents from the 'crops' collection.
  Future<List<CropModel>> fetchAllCrops() async {
    try {
      final snapshot = await _firestore.collection(_cropsCollection).get();
      return snapshot.docs
          .map((doc) => CropModel.fromJson(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch crops: $e');
    }
  }

  /// Save a recommendation record to Firestore.
  Future<String> saveRecommendation(RecommendationModel recommendation) async {
    try {
      final docRef = await _firestore
          .collection(_recommendationsCollection)
          .add(recommendation.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save recommendation: $e');
    }
  }

  /// Fetch recommendation history for a specific user, ordered by date desc.
  Future<List<RecommendationModel>> fetchHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_recommendationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) =>
              RecommendationModel.fromJson(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch history: $e');
    }
  }

  /// Fetch a single recommendation by document ID.
  Future<RecommendationModel?> fetchRecommendationById(String docId) async {
    try {
      final doc = await _firestore
          .collection(_recommendationsCollection)
          .doc(docId)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return RecommendationModel.fromJson(doc.data()!, docId: doc.id);
    } catch (e) {
      throw Exception('Failed to fetch recommendation: $e');
    }
  }
}

