import '../models/crop_model.dart';
import '../models/recommendation_model.dart';
import 'crop_repository.dart';

/// Service containing the deterministic weighted scoring engine
/// for crop recommendation.
class RecommendationService {
  final CropRepository _repository = CropRepository();

  // ── Scoring Weights ──
  static const double _weightN = 1.2;
  static const double _weightP = 1.0;
  static const double _weightK = 1.0;
  static const double _weightTemperature = 1.5;
  static const double _weightHumidity = 1.0;
  static const double _weightPH = 1.5;
  static const double _weightRainfall = 1.3;

  static const double _totalWeight =
      _weightN +
      _weightP +
      _weightK +
      _weightTemperature +
      _weightHumidity +
      _weightPH +
      _weightRainfall;

  /// Compute a single parameter score.
  ///
  /// If user value is inside [minVal, maxVal]:
  ///   score = 1 - (|userValue - meanVal| / (maxVal - minVal))
  /// Else:
  ///   score = 0
  ///
  /// Result is clamped to [0, 1].
  double _parameterScore(
    double userValue,
    double minVal,
    double maxVal,
    double meanVal,
  ) {
    if (userValue < minVal || userValue > maxVal) return 0.0;
    final range = maxVal - minVal;
    if (range <= 0) return 0.0;
    final score = 1.0 - ((userValue - meanVal).abs() / range);
    return score.clamp(0.0, 1.0);
  }

  /// Compute the final weighted score for a single crop.
  double _computeCropScore(CropModel crop, CropInput input) {
    final scores = [
      _parameterScore(input.n, crop.minN, crop.maxN, crop.meanN) * _weightN,
      _parameterScore(input.p, crop.minP, crop.maxP, crop.meanP) * _weightP,
      _parameterScore(input.k, crop.minK, crop.maxK, crop.meanK) * _weightK,
      _parameterScore(
            input.temperature,
            crop.minTemperature,
            crop.maxTemperature,
            crop.meanTemperature,
          ) *
          _weightTemperature,
      _parameterScore(
            input.humidity,
            crop.minHumidity,
            crop.maxHumidity,
            crop.meanHumidity,
          ) *
          _weightHumidity,
      _parameterScore(input.ph, crop.minPH, crop.maxPH, crop.meanPH) *
          _weightPH,
      _parameterScore(
            input.rainfall,
            crop.minRainfall,
            crop.maxRainfall,
            crop.meanRainfall,
          ) *
          _weightRainfall,
    ];

    final weightedSum = scores.fold(0.0, (sum, s) => sum + s);
    return (weightedSum / _totalWeight).clamp(0.0, 1.0);
  }

  /// Run the recommendation engine.
  ///
  /// 1. Fetch all crops from Firestore (single read).
  /// 2. Score each crop using weighted scoring.
  /// 3. Sort descending and return top 3.
  /// 4. Save the recommendation record.
  ///
  /// Returns the list of top 3 [CropResult] and the saved record ID.
  Future<RecommendationModel> getRecommendations({
    required CropInput input,
    required String userId,
  }) async {
    // Fetch crops once
    final crops = await _repository.fetchAllCrops();

    if (crops.isEmpty) {
      throw Exception('No crop data available in database.');
    }

    // Score all crops
    final scoredCrops = <MapEntry<String, double>>[];
    for (final crop in crops) {
      final score = _computeCropScore(crop, input);
      scoredCrops.add(
        MapEntry(crop.name.isNotEmpty ? crop.name : crop.id, score),
      );
    }

    // Sort descending by score
    scoredCrops.sort((a, b) => b.value.compareTo(a.value));

    // Take top 3
    final top3 = scoredCrops.take(3).map((entry) {
      final percentage = double.parse((entry.value * 100).toStringAsFixed(1));
      return CropResult(
        cropName: entry.key,
        score: double.parse(entry.value.toStringAsFixed(4)),
        suitabilityPercentage: percentage,
      );
    }).toList();

    // Build recommendation model
    final recommendation = RecommendationModel(
      id: '', // will be assigned by Firestore
      userId: userId,
      input: input,
      results: top3,
      createdAt: DateTime.now(), // server timestamp used in toJson
    );

    // Save to Firestore
    final docId = await _repository.saveRecommendation(recommendation);

    // Return with the assigned document ID
    return RecommendationModel(
      id: docId,
      userId: userId,
      input: input,
      results: top3,
      createdAt: DateTime.now(),
    );
  }

  /// Fetch user's recommendation history.
  Future<List<RecommendationModel>> getHistory(String userId) {
    return _repository.fetchHistory(userId);
  }
}
