
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_model.dart';

class CropRemoteService {
  static final CropRemoteService instance =
  CropRemoteService._();
  CropRemoteService._();

  final _col = FirebaseFirestore.instance.collection('crops');

  // ── CREATE / UPDATE ──
  Future<void> upsertCrop(CropRecord crop) async {
    await _col.doc(crop.id).set(crop.toMap());
  }

  // ── GET ALL ──
  Future<List<CropRecord>> getCrops(String userId) async {
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => CropRecord.fromFirestore(d))
        .toList();
  }

  // ── DELETE ──
  Future<void> deleteCrop(String cropId) async {
    await _col.doc(cropId).delete();
  }

  // ── REALTIME STREAM ──
  Stream<List<CropRecord>> cropsStream(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => CropRecord.fromFirestore(d))
        .toList());
  }
}