import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import '../../../app/data/services/cloudinary_service.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/field_visit_model.dart';
import '../repository/appointment_repository.dart';

// dart:io removed — XFile + Uint8List used for web compatibility
class AppointmentController extends GetxController {
  final AppointmentRepository _service = Get.find<AppointmentRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();

  final RxList<UserModel> experts = <UserModel>[].obs;
  final RxList<FieldVisitModel> farmerVisits = <FieldVisitModel>[].obs;
  final Rx<UserModel?> selectedExpert = Rx<UserModel?>(null);

  final RxBool isLoadingExperts = false.obs;
  final RxBool isLoadingVisits = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isUploadingImages = false.obs;

  final TextEditingController cropTypeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController farmSizeController = TextEditingController();
  final TextEditingController locationNameController = TextEditingController();

  final RxString selectedProblemCategory = ''.obs;
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  // XFile instead of File
  final RxList<XFile> selectedImages = <XFile>[].obs;
  // Cached bytes for Image.memory preview
  final RxList<Uint8List> selectedImageBytes = <Uint8List>[].obs;

  final RxList<String> uploadedImageUrls = <String>[].obs;
  final RxDouble currentLat = 0.0.obs;
  final RxDouble currentLng = 0.0.obs;

  static const List<String> problemCategories = [
    'Disease', 'Pest', 'Low Yield', 'Soil', 'Irrigation', 'Other',
  ];

  @override
  void onInit() {
    super.onInit();
    _prefillFarmerData();
  }

  void _prefillFarmerData() {
    final user = _authRepository.currentUser.value;
    if (user != null) {
      locationNameController.text = user.location ?? '';
      farmSizeController.text = user.farmSize ?? '';
    }
  }

  Future<void> loadExperts() async {
    try {
      isLoadingExperts.value = true;
      final result = await _service.fetchExperts();
      experts.assignAll(result);
    } catch (e) {
      debugPrint('[AppointmentController] loadExperts error: $e');
      AppSnackbar.error('Unable to load experts. Please try again.');
    } finally {
      isLoadingExperts.value = false;
    }
  }

  void selectExpert(UserModel expert) => selectedExpert.value = expert;

  Future<void> loadFarmerVisits() async {
    final user = _authRepository.currentUser.value;
    if (user == null) return;
    try {
      isLoadingVisits.value = true;
      final result = await _service.fetchFarmerVisits(user.uid);
      farmerVisits.assignAll(result);
    } catch (e) {
      debugPrint('[AppointmentController] loadFarmerVisits error: $e');
      AppSnackbar.error('Unable to load your visits. Please try again.');
    } finally {
      isLoadingVisits.value = false;
    }
  }

  Future<void> cancelVisit(String visitId) async {
    try {
      await _service.cancelVisit(visitId);
      AppSnackbar.success('Visit request cancelled.');
      await loadFarmerVisits();
    } catch (e) {
      debugPrint('[AppointmentController] cancelVisit error: $e');
      AppSnackbar.error(e.toString());
    }
  }

  // ── Image handling ─────────────────────────────────────────────────────

  Future<void> pickImages() async {
    try {
      final remaining = 3 - selectedImages.length;
      if (remaining <= 0) {
        AppSnackbar.warning('Maximum 3 images allowed.');
        return;
      }
      final List<XFile> images = await ImagePicker().pickMultiImage(
        maxWidth: 1024, maxHeight: 1024, imageQuality: 80,
      );
      if (images.isNotEmpty) {
        for (final xf in images.take(remaining)) {
          final bytes = await xf.readAsBytes();
          selectedImages.add(xf);
          selectedImageBytes.add(bytes);
        }
      }
    } catch (e) {
      debugPrint('[AppointmentController] pickImages error: $e');
      AppSnackbar.error('Failed to pick images.');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      selectedImageBytes.removeAt(index);
    }
  }

  // Upload using bytes — no dart:io File needed
  Future<List<String>> _uploadImages() async {
    final List<String> urls = [];
    for (int i = 0; i < selectedImages.length; i++) {
      final xf = selectedImages[i];
      final bytes = selectedImageBytes[i];
      final fileName = xf.name.isNotEmpty
          ? xf.name
          : 'visit_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

      final url = await _cloudinaryService.uploadImage(
        bytes, fileName, folder: 'field_visits',
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }

  // ── Location ───────────────────────────────────────────────────────────

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppSnackbar.warning('Location permission is needed for farm location.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        AppSnackbar.warning(
            'Location permission permanently denied. Enable it in settings.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      currentLat.value = position.latitude;
      currentLng.value = position.longitude;
      AppSnackbar.success('Location captured successfully!');
    } catch (e) {
      debugPrint('[AppointmentController] getCurrentLocation error: $e');
      AppSnackbar.error('Unable to get your location. Please try again.');
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Select Preferred Visit Date',
      confirmText: 'Select',
      cancelText: 'Cancel',
    );
    if (picked != null) selectedDate.value = picked;
  }

  // ── Validation ─────────────────────────────────────────────────────────

  bool validateForm() {
    if (cropTypeController.text.trim().isEmpty) {
      AppSnackbar.warning('Please enter the crop type.');
      return false;
    }
    if (selectedProblemCategory.value.isEmpty) {
      AppSnackbar.warning('Please select a problem category.');
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      AppSnackbar.warning('Please describe the problem.');
      return false;
    }
    if (selectedDate.value == null) {
      AppSnackbar.warning('Please select a preferred date.');
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      AppSnackbar.warning('Please enter your full address.');
      return false;
    }
    if (currentLat.value == 0.0 && currentLng.value == 0.0) {
      AppSnackbar.warning('Please capture your farm location using GPS.');
      return false;
    }
    if (farmSizeController.text.trim().isEmpty) {
      AppSnackbar.warning('Please enter your farm size.');
      return false;
    }
    return true;
  }

  // ── Submit ─────────────────────────────────────────────────────────────

  Future<void> submitVisitRequest() async {
    if (isSubmitting.value) return;
    if (!validateForm()) return;
    if (selectedExpert.value == null) {
      AppSnackbar.error('No expert selected.');
      return;
    }

    final user = _authRepository.currentUser.value;
    if (user == null || user.uid.isEmpty) {
      AppSnackbar.error('You must be logged in to request a visit.');
      return;
    }
    if (!user.isProfileComplete) {
      AppSnackbar.warning('Please complete your profile before requesting a visit.');
      return;
    }
    if (user.userType != 'farmer') {
      AppSnackbar.error('Only farmers can request field visits.');
      return;
    }

    try {
      isSubmitting.value = true;

      List<String> imageUrls = [];
      if (selectedImages.isNotEmpty) {
        isUploadingImages.value = true;
        imageUrls = await _uploadImages();
        isUploadingImages.value = false;
      }

      final expert = selectedExpert.value!;
      final visit = FieldVisitModel(
        id: '',
        farmerId: user.uid,
        farmerName: user.name,
        expertId: expert.uid,
        expertName: expert.name,
        cropType: cropTypeController.text.trim(),
        problemCategory: selectedProblemCategory.value,
        description: descriptionController.text.trim(),
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        farmLocationName: locationNameController.text.trim(),
        latitude: currentLat.value,
        longitude: currentLng.value,
        fullAddress: addressController.text.trim(),
        farmSize: double.tryParse(farmSizeController.text.trim()) ?? 0.0,
        preferredDate: selectedDate.value!,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _service.createVisitRequest(visit);
      AppSnackbar.success('Visit request sent successfully!');
      _clearForm();
      Get.back();
    } catch (e) {
      debugPrint('[AppointmentController] submitVisitRequest error: $e');
      AppSnackbar.error('Failed to submit visit request. Please try again.');
    } finally {
      isSubmitting.value = false;
      isUploadingImages.value = false;
    }
  }

  void _clearForm() {
    cropTypeController.clear();
    descriptionController.clear();
    addressController.clear();
    selectedProblemCategory.value = '';
    selectedDate.value = null;
    selectedImages.clear();
    selectedImageBytes.clear();
    uploadedImageUrls.clear();
    currentLat.value = 0.0;
    currentLng.value = 0.0;
    _prefillFarmerData();
  }

  @override
  void onClose() {
    cropTypeController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    farmSizeController.dispose();
    locationNameController.dispose();
    super.onClose();
  }
}