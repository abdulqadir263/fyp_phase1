import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../app/data/providers/auth_provider.dart';
import '../../../app/data/services/cloudinary_service.dart';
import '../../../app/data/models/user_model.dart';
import '../../../app/utils/app_snackbar.dart';
import '../models/field_visit_model.dart';
import '../services/appointment_service.dart';

/// AppointmentController — Handles farmer-side field visit logic
/// Browse experts, request visits, view own visits, cancel
class AppointmentController extends GetxController {
  final AppointmentService _service = Get.find<AppointmentService>();
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();

  // ─────────────────────────────────────────────
  // OBSERVABLE STATE
  // ─────────────────────────────────────────────

  /// List of available experts
  final RxList<UserModel> experts = <UserModel>[].obs;

  /// Farmer's own visit requests
  final RxList<FieldVisitModel> farmerVisits = <FieldVisitModel>[].obs;

  /// Currently selected expert (for request flow)
  final Rx<UserModel?> selectedExpert = Rx<UserModel?>(null);

  /// Loading states
  final RxBool isLoadingExperts = false.obs;
  final RxBool isLoadingVisits = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isUploadingImages = false.obs;

  // ─────────────────────────────────────────────
  // FORM CONTROLLERS (Request Visit)
  // ─────────────────────────────────────────────

  final TextEditingController cropTypeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController farmSizeController = TextEditingController();
  final TextEditingController locationNameController = TextEditingController();

  /// Selected problem category
  final RxString selectedProblemCategory = ''.obs;

  /// Selected preferred date
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  /// Selected images for upload
  final RxList<File> selectedImages = <File>[].obs;

  /// Uploaded image URLs after Cloudinary upload
  final RxList<String> uploadedImageUrls = <String>[].obs;

  /// Current GPS coordinates
  final RxDouble currentLat = 0.0.obs;
  final RxDouble currentLng = 0.0.obs;

  // ─────────────────────────────────────────────
  // CONSTANTS
  // ─────────────────────────────────────────────

  /// Problem categories for dropdown
  static const List<String> problemCategories = [
    'Disease',
    'Pest',
    'Low Yield',
    'Soil',
    'Irrigation',
    'Other',
  ];

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    debugPrint('[AppointmentController] Initialized');
    _prefillFarmerData();
  }

  /// Pre-fill form fields from farmer's profile
  void _prefillFarmerData() {
    final user = _authProvider.currentUser.value;
    if (user != null) {
      locationNameController.text = user.location ?? '';
      farmSizeController.text = user.farmSize ?? '';
    }
  }

  // ─────────────────────────────────────────────
  // EXPERT LIST
  // ─────────────────────────────────────────────

  /// Load all available experts
  Future<void> loadExperts() async {
    try {
      isLoadingExperts.value = true;
      debugPrint('[AppointmentController] Loading experts...');
      final result = await _service.fetchExperts();
      experts.assignAll(result);
      debugPrint('[AppointmentController] Loaded ${result.length} experts');
    } catch (e) {
      debugPrint('[AppointmentController] Error loading experts: $e');
      AppSnackbar.error('Unable to load experts. Please try again.');
    } finally {
      isLoadingExperts.value = false;
    }
  }

  /// Select an expert for visit request
  void selectExpert(UserModel expert) {
    selectedExpert.value = expert;
  }

  // ─────────────────────────────────────────────
  // FARMER VISITS
  // ─────────────────────────────────────────────

  /// Load farmer's own visit requests
  Future<void> loadFarmerVisits() async {
    final user = _authProvider.currentUser.value;
    if (user == null) return;

    try {
      isLoadingVisits.value = true;
      final result = await _service.fetchFarmerVisits(user.uid);
      farmerVisits.assignAll(result);
    } catch (e) {
      debugPrint('[AppointmentController] Error loading farmer visits: $e');
      AppSnackbar.error('Unable to load your visits. Please try again.');
    } finally {
      isLoadingVisits.value = false;
    }
  }

  /// Cancel a pending visit request
  Future<void> cancelVisit(String visitId) async {
    try {
      await _service.cancelVisit(visitId);
      AppSnackbar.success('Visit request cancelled.');
      await loadFarmerVisits(); // Refresh list
    } catch (e) {
      debugPrint('[AppointmentController] Error cancelling visit: $e');
      AppSnackbar.error(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // IMAGE HANDLING
  // ─────────────────────────────────────────────

  /// Pick images from gallery (max 3)
  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        // Limit to 3 images total
        final remaining = 3 - selectedImages.length;
        if (remaining <= 0) {
          AppSnackbar.warning('Maximum 3 images allowed.');
          return;
        }
        final toAdd = images.take(remaining).map((x) => File(x.path)).toList();
        selectedImages.addAll(toAdd);
      }
    } catch (e) {
      debugPrint('[AppointmentController] Error picking images: $e');
      AppSnackbar.error('Failed to pick images.');
    }
  }

  /// Remove a selected image
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  /// Upload selected images to Cloudinary
  Future<List<String>> _uploadImages() async {
    final List<String> urls = [];
    for (final file in selectedImages) {
      final url = await _cloudinaryService.uploadImage(
        file,
        folder: 'field_visits',
      );
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  // ─────────────────────────────────────────────
  // LOCATION
  // ─────────────────────────────────────────────

  /// Get current GPS location
  Future<void> getCurrentLocation() async {
    try {
      // Check permission
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
            'Location permission is permanently denied. Please enable it in settings.');
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
      debugPrint('[AppointmentController] Error getting location: $e');
      AppSnackbar.error('Unable to get your location. Please try again.');
    }
  }

  // ─────────────────────────────────────────────
  // DATE PICKER
  // ─────────────────────────────────────────────

  /// Show date picker and set selected date
  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)), // Cannot select past/today
      lastDate: now.add(const Duration(days: 90)), // Up to 3 months
      helpText: 'Select Preferred Visit Date',
      confirmText: 'Select',
      cancelText: 'Cancel',
    );

    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  // ─────────────────────────────────────────────
  // FORM VALIDATION
  // ─────────────────────────────────────────────

  /// Validate the visit request form
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

  // ─────────────────────────────────────────────
  // SUBMIT REQUEST
  // ─────────────────────────────────────────────

  /// Submit the field visit request to Firestore
  Future<void> submitVisitRequest() async {
    if (isSubmitting.value) return;
    if (!validateForm()) return;
    if (selectedExpert.value == null) {
      AppSnackbar.error('No expert selected.');
      return;
    }

    final user = _authProvider.currentUser.value;
    if (user == null) {
      AppSnackbar.error('You must be logged in to request a visit.');
      return;
    }

    try {
      isSubmitting.value = true;

      // Upload images if any
      List<String> imageUrls = [];
      if (selectedImages.isNotEmpty) {
        isUploadingImages.value = true;
        imageUrls = await _uploadImages();
        isUploadingImages.value = false;
      }

      final expert = selectedExpert.value!;

      final visit = FieldVisitModel(
        id: '', // Will be set by Firestore
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

      // Clear form
      _clearForm();

      // Go back to farmer visits
      Get.back();
    } catch (e) {
      debugPrint('[AppointmentController] Error submitting visit: $e');
      AppSnackbar.error('Failed to submit visit request. Please try again.');
    } finally {
      isSubmitting.value = false;
      isUploadingImages.value = false;
    }
  }

  /// Clear all form fields after submission
  void _clearForm() {
    cropTypeController.clear();
    descriptionController.clear();
    addressController.clear();
    selectedProblemCategory.value = '';
    selectedDate.value = null;
    selectedImages.clear();
    uploadedImageUrls.clear();
    currentLat.value = 0.0;
    currentLng.value = 0.0;
    // Keep pre-filled data from profile
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

