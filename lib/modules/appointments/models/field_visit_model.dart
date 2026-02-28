import 'package:cloud_firestore/cloud_firestore.dart';

/// FieldVisitModel — Represents a physical farm inspection visit request
/// Stored in Firestore collection: 'fieldVisits'
class FieldVisitModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String expertId;
  final String expertName;

  // Problem details
  final String cropType;
  final String problemCategory;
  final String description;
  final List<String>? imageUrls;

  // Farm location details
  final String farmLocationName;
  final double latitude;
  final double longitude;
  final String fullAddress;
  final double farmSize;

  // Scheduling
  final DateTime preferredDate;
  final DateTime? confirmedDate;

  // Status: pending | accepted | scheduled | rejected | completed | cancelled
  final String status;

  // Expert feedback after visit
  final String? expertNotes;

  final DateTime createdAt;

  FieldVisitModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.expertId,
    required this.expertName,
    required this.cropType,
    required this.problemCategory,
    required this.description,
    this.imageUrls,
    required this.farmLocationName,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    required this.farmSize,
    required this.preferredDate,
    this.confirmedDate,
    required this.status,
    this.expertNotes,
    required this.createdAt,
  });

  /// Create from Firestore document snapshot
  factory FieldVisitModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FieldVisitModel(
      id: doc.id,
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
      expertId: data['expertId'] ?? '',
      expertName: data['expertName'] ?? '',
      cropType: data['cropType'] ?? '',
      problemCategory: data['problemCategory'] ?? '',
      description: data['description'] ?? '',
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
      farmLocationName: data['farmLocationName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      fullAddress: data['fullAddress'] ?? '',
      farmSize: (data['farmSize'] ?? 0.0).toDouble(),
      preferredDate: (data['preferredDate'] as Timestamp).toDate(),
      confirmedDate: data['confirmedDate'] != null
          ? (data['confirmedDate'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      expertNotes: data['expertNotes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Create from Map (for JSON-like usage)
  factory FieldVisitModel.fromMap(Map<String, dynamic> data, String docId) {
    return FieldVisitModel(
      id: docId,
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
      expertId: data['expertId'] ?? '',
      expertName: data['expertName'] ?? '',
      cropType: data['cropType'] ?? '',
      problemCategory: data['problemCategory'] ?? '',
      description: data['description'] ?? '',
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
      farmLocationName: data['farmLocationName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      fullAddress: data['fullAddress'] ?? '',
      farmSize: (data['farmSize'] ?? 0.0).toDouble(),
      preferredDate: data['preferredDate'] is Timestamp
          ? (data['preferredDate'] as Timestamp).toDate()
          : DateTime.now(),
      confirmedDate: data['confirmedDate'] != null && data['confirmedDate'] is Timestamp
          ? (data['confirmedDate'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      expertNotes: data['expertNotes'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toDocument() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      'expertId': expertId,
      'expertName': expertName,
      'cropType': cropType,
      'problemCategory': problemCategory,
      'description': description,
      'imageUrls': imageUrls,
      'farmLocationName': farmLocationName,
      'latitude': latitude,
      'longitude': longitude,
      'fullAddress': fullAddress,
      'farmSize': farmSize,
      'preferredDate': Timestamp.fromDate(preferredDate),
      'confirmedDate': confirmedDate != null
          ? Timestamp.fromDate(confirmedDate!)
          : null,
      'status': status,
      'expertNotes': expertNotes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  FieldVisitModel copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? expertId,
    String? expertName,
    String? cropType,
    String? problemCategory,
    String? description,
    List<String>? imageUrls,
    String? farmLocationName,
    double? latitude,
    double? longitude,
    String? fullAddress,
    double? farmSize,
    DateTime? preferredDate,
    DateTime? confirmedDate,
    String? status,
    String? expertNotes,
    DateTime? createdAt,
  }) {
    return FieldVisitModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      expertId: expertId ?? this.expertId,
      expertName: expertName ?? this.expertName,
      cropType: cropType ?? this.cropType,
      problemCategory: problemCategory ?? this.problemCategory,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      farmLocationName: farmLocationName ?? this.farmLocationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fullAddress: fullAddress ?? this.fullAddress,
      farmSize: farmSize ?? this.farmSize,
      preferredDate: preferredDate ?? this.preferredDate,
      confirmedDate: confirmedDate ?? this.confirmedDate,
      status: status ?? this.status,
      expertNotes: expertNotes ?? this.expertNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Status display helpers
  /// Returns a user-friendly label for the status
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'scheduled':
        return 'Scheduled';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  /// Google Maps URL for opening farm location externally
  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

