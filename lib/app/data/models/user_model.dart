import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/values/constants.dart';

/// UserModel - Updated to support role-based profile fields
/// Supports: Farmer, Expert, Company (Seller), Guest
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

  // ========== NEW FARMER FIELDS ==========
  /// List of crops grown by farmer (multi-select)
  final List<String>? cropsGrown;

  // ========== NEW EXPERT FIELDS ==========
  /// Years of professional experience
  final int? yearsOfExperience;
  /// Professional certifications
  final String? certifications;
  /// Short biography (max 200 chars)
  final String? bio;
  /// Whether expert is available for consultation
  final bool? isAvailableForConsultation;

  // ========== NEW COMPANY/SELLER FIELDS ==========
  /// Type of agricultural business
  final String? businessType;
  /// Years company has been in business
  final int? yearsInBusiness;
  /// Business license number (optional)
  final String? licenseNumber;
  /// Short business description (max 200 chars)
  final String? businessDescription;

  // ========== PROFILE COMPLETION FLAG ==========
  /// Flag to track if initial profile setup is complete
  final bool isProfileComplete;

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
    // New farmer fields
    this.cropsGrown,
    // New expert fields
    this.yearsOfExperience,
    this.certifications,
    this.bio,
    this.isAvailableForConsultation,
    // New company fields
    this.businessType,
    this.yearsInBusiness,
    this.licenseNumber,
    this.businessDescription,
    // Profile completion flag
    this.isProfileComplete = false,
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
      // New farmer fields
      cropsGrown: data['cropsGrown'] != null
          ? List<String>.from(data['cropsGrown'])
          : null,
      // New expert fields
      yearsOfExperience: data['yearsOfExperience'],
      certifications: data['certifications'],
      bio: data['bio'],
      isAvailableForConsultation: data['isAvailableForConsultation'],
      // New company fields
      businessType: data['businessType'],
      yearsInBusiness: data['yearsInBusiness'],
      licenseNumber: data['licenseNumber'],
      businessDescription: data['businessDescription'],
      // Profile completion flag
      isProfileComplete: data['isProfileComplete'] ?? false,
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
      // New farmer fields
      'cropsGrown': cropsGrown,
      // New expert fields
      'yearsOfExperience': yearsOfExperience,
      'certifications': certifications,
      'bio': bio,
      'isAvailableForConsultation': isAvailableForConsultation,
      // New company fields
      'businessType': businessType,
      'yearsInBusiness': yearsInBusiness,
      'licenseNumber': licenseNumber,
      'businessDescription': businessDescription,
      // Profile completion flag
      'isProfileComplete': isProfileComplete,
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? userType,
    String? location,
    String? farmSize,
    String? specialization,
    String? companyName,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? cropsGrown,
    int? yearsOfExperience,
    String? certifications,
    String? bio,
    bool? isAvailableForConsultation,
    String? businessType,
    int? yearsInBusiness,
    String? licenseNumber,
    String? businessDescription,
    bool? isProfileComplete,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      location: location ?? this.location,
      farmSize: farmSize ?? this.farmSize,
      specialization: specialization ?? this.specialization,
      companyName: companyName ?? this.companyName,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cropsGrown: cropsGrown ?? this.cropsGrown,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      certifications: certifications ?? this.certifications,
      bio: bio ?? this.bio,
      isAvailableForConsultation: isAvailableForConsultation ?? this.isAvailableForConsultation,
      businessType: businessType ?? this.businessType,
      yearsInBusiness: yearsInBusiness ?? this.yearsInBusiness,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      businessDescription: businessDescription ?? this.businessDescription,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}