import 'package:cloud_firestore/cloud_firestore.dart';

/// AppointmentModel — Represents a slot-based consultation booking.
/// Collection: 'appointments'
/// Distinct from FieldVisitModel (which is for physical farm visits).
class AppointmentModel {
  final String id;
  final String expertUid;
  final String farmerUid;
  final String farmerName;
  final String expertName;
  final String day;
  final String slot;

  /// "pending" | "confirmed" | "cancelled" | "completed"
  final String status;

  final DateTime bookedAt;
  final String consultationMode;
  final int fee;

  AppointmentModel({
    required this.id,
    required this.expertUid,
    required this.farmerUid,
    required this.farmerName,
    required this.expertName,
    required this.day,
    required this.slot,
    required this.status,
    required this.bookedAt,
    required this.consultationMode,
    required this.fee,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      expertUid: data['expertUid'] ?? '',
      farmerUid: data['farmerUid'] ?? '',
      farmerName: data['farmerName'] ?? '',
      expertName: data['expertName'] ?? '',
      day: data['day'] ?? '',
      slot: data['slot'] ?? '',
      status: data['status'] ?? 'pending',
      bookedAt: data['bookedAt'] != null
          ? (data['bookedAt'] as Timestamp).toDate()
          : DateTime.now(),
      consultationMode: data['consultationMode'] ?? '',
      fee: (data['fee'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expertUid': expertUid,
      'farmerUid': farmerUid,
      'farmerName': farmerName,
      'expertName': expertName,
      'day': day,
      'slot': slot,
      'status': status,
      'bookedAt': Timestamp.fromDate(bookedAt),
      'consultationMode': consultationMode,
      'fee': fee,
    };
  }

  /// Returns color-coded status label context
  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }
}
