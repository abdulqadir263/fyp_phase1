import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveFarmerProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('farmers').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getFarmerProfile(String uid) async {
    final doc = await _firestore.collection('farmers').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}
