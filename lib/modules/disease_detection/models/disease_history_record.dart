import 'package:cloud_firestore/cloud_firestore.dart';

/// A single saved disease detection result stored in Firestore.
class DiseaseHistoryRecord {
  final String id;
  final String userId;
  final String diseaseName;
  final String diseaseNameUr;
  final double confidence;
  final String severity;
  final String severityUr;
  final String description;
  final String descriptionUr;
  final String treatment;
  final String treatmentUr;
  final String prevention;
  final String preventionUr;
  final String farmerTip;
  final String farmerTipUr;
  final DateTime createdAt;

  const DiseaseHistoryRecord({
    required this.id,
    required this.userId,
    required this.diseaseName,
    required this.diseaseNameUr,
    required this.confidence,
    required this.severity,
    required this.severityUr,
    required this.description,
    required this.descriptionUr,
    required this.treatment,
    required this.treatmentUr,
    required this.prevention,
    required this.preventionUr,
    required this.farmerTip,
    required this.farmerTipUr,
    required this.createdAt,
  });

  factory DiseaseHistoryRecord.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    return DiseaseHistoryRecord(
      id: docId ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      diseaseName: json['diseaseName'] as String? ?? '',
      diseaseNameUr: json['diseaseNameUr'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'none',
      severityUr: json['severityUr'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionUr: json['descriptionUr'] as String? ?? '',
      treatment: json['treatment'] as String? ?? '',
      treatmentUr: json['treatmentUr'] as String? ?? '',
      prevention: json['prevention'] as String? ?? '',
      preventionUr: json['preventionUr'] as String? ?? '',
      farmerTip: json['farmerTip'] as String? ?? '',
      farmerTipUr: json['farmerTipUr'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'diseaseName': diseaseName,
        'diseaseNameUr': diseaseNameUr,
        'confidence': confidence,
        'severity': severity,
        'severityUr': severityUr,
        'description': description,
        'descriptionUr': descriptionUr,
        'treatment': treatment,
        'treatmentUr': treatmentUr,
        'prevention': prevention,
        'preventionUr': preventionUr,
        'farmerTip': farmerTip,
        'farmerTipUr': farmerTipUr,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
