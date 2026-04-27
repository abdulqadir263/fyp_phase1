import 'package:firebase_auth/firebase_auth.dart';

import '../models/recommendation_model.dart';
import '../repository/crop_repository.dart';
import '../services/crop_recommender.dart';

/// Repository that coordinates TFLite inference + Firestore persistence.
///
/// The old rule-based weighted-scoring engine has been removed.
/// All inference is now delegated to [CropRecommender].
class RecommendationRepository {
  final CropRepository _cropRepo;
  final CropRecommender _recommender;

  RecommendationRepository({
    CropRepository? cropRepo,
    required CropRecommender recommender,
  })  : _cropRepo = cropRepo ?? CropRepository(),
        _recommender = recommender;

  // ── Inference + persistence ───────────────────────────────────────────────

  /// Run on-device TFLite inference and save the result to Firestore.
  ///
  /// Returns the saved [RecommendationModel] with the assigned Firestore ID.
  Future<RecommendationModel> getRecommendations({
    required CropInput input,
    required String userId,
  }) async {
    // Run synchronous TFLite inference (no network call)
    final top3 = _recommender.recommend(input);

    final recommendation = RecommendationModel(
      id: '', // assigned by Firestore
      userId: userId.isNotEmpty
          ? userId
          : FirebaseAuth.instance.currentUser?.uid ?? '',
      input: input,
      results: top3,
      createdAt: DateTime.now(),
    );

    // Persist to Firestore (history stays intact)
    final docId = await _cropRepo.saveRecommendation(recommendation);

    return RecommendationModel(
      id: docId,
      userId: recommendation.userId,
      input: input,
      results: top3,
      createdAt: recommendation.createdAt,
    );
  }

  // ── History (Firestore read — unchanged) ─────────────────────────────────

  /// Fetch recommendation history for [userId] from Firestore.
  Future<List<RecommendationModel>> getHistory(String userId) {
    return _cropRepo.fetchHistory(userId);
  }
}
