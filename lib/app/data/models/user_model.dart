import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/values/constants.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String userType;
  final String? location;
  final String? farmSize;
  final String? specialization;
  final String? companyName;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.location,
    this.farmSize,
    this.specialization,
    this.companyName,
    this.profileImage,
    required this.createdAt,
    this.updatedAt,
  });



  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      userType: data['userType'] ?? AppConstants.USER_TYPE_FARMER,
      location: data['location'],
      farmSize: data['farmSize'],
      specialization: data['specialization'],
      companyName: data['companyName'],
      profileImage: data['profileImage'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }


  Map<String, dynamic> toDocument() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'location': location,
      'farmSize': farmSize,
      'specialization': specialization,
      'companyName': companyName,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : null,
    };
  }
}