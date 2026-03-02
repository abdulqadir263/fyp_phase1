import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single crop result within a recommendation.
class CropResult {
  final String cropName;
  final double score;
  final double suitabilityPercentage;

  CropResult({
    required this.cropName,
    required this.score,
    required this.suitabilityPercentage,
  });

  factory CropResult.fromJson(Map<String, dynamic> json) {
    return CropResult(
      cropName: json['cropName'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      suitabilityPercentage:
          (json['suitabilityPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cropName': cropName,
      'score': score,
      'suitabilityPercentage': suitabilityPercentage,
    };
  }
}

/// User input parameters for crop recommendation.
class CropInput {
  final double n;
  final double p;
  final double k;
  final double temperature;
  final double humidity;
  final double ph;
  final double rainfall;

  CropInput({
    required this.n,
    required this.p,
    required this.k,
    required this.temperature,
    required this.humidity,
    required this.ph,
    required this.rainfall,
  });

  factory CropInput.fromJson(Map<String, dynamic> json) {
    return CropInput(
      n: (json['N'] as num?)?.toDouble() ?? 0.0,
      p: (json['P'] as num?)?.toDouble() ?? 0.0,
      k: (json['K'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      ph: (json['ph'] as num?)?.toDouble() ?? 0.0,
      rainfall: (json['rainfall'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'N': n,
      'P': p,
      'K': k,
      'temperature': temperature,
      'humidity': humidity,
      'ph': ph,
      'rainfall': rainfall,
    };
  }
}

/// Model for a saved recommendation record in Firestore.
class RecommendationModel {
  final String id;
  final String userId;
  final CropInput input;
  final List<CropResult> results;
  final DateTime createdAt;

  RecommendationModel({
    required this.id,
    required this.userId,
    required this.input,
    required this.results,
    required this.createdAt,
  });

  /// Create from Firestore document.
  factory RecommendationModel.fromJson(Map<String, dynamic> json,
      {String? docId}) {
    return RecommendationModel(
      id: docId ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      input: CropInput.fromJson(
          Map<String, dynamic>.from(json['input'] ?? {})),
      results: (json['results'] as List<dynamic>?)
              ?.map((e) =>
                  CropResult.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'input': input.toJson(),
      'results': results.map((r) => r.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Top crop name for display in history list.
  String get topCropName =>
      results.isNotEmpty ? results.first.cropName : 'N/A';

  /// Top suitability percentage for display.
  double get topSuitability =>
      results.isNotEmpty ? results.first.suitabilityPercentage : 0.0;
}

