import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recommendation_model.dart';
import '../repository/recommendation_repository.dart';
import '../services/crop_recommender.dart';

/// Controller for the Crop Recommendation module.
/// Manages input form state, TFLite inference, results, and history.
class CropRecommendationController extends GetxController {
  // ── TFLite service (initialised once in onInit) ───────────────────────────
  final CropRecommender _recommender = CropRecommender();
  late final RecommendationRepository _service;

  // ── Form Controllers ──────────────────────────────────────────────────────
  final nController = TextEditingController();
  final pController = TextEditingController();
  final kController = TextEditingController();
  final temperatureController = TextEditingController();
  final humidityController = TextEditingController();
  final phController = TextEditingController();
  final rainfallController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  // ── Observable State ──────────────────────────────────────────────────────
  final isLoading = false.obs;
  final isHistoryLoading = false.obs;
  final errorMessage = ''.obs;

  final Rx<RecommendationModel?> currentRecommendation =
      Rx<RecommendationModel?>(null);
  final RxList<RecommendationModel> history = <RecommendationModel>[].obs;

  /// Current user ID from FirebaseAuth.
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Wire the recommender into the repository, then warm up the interpreter.
    _service = RecommendationRepository(recommender: _recommender);
    _initializeRecommender();
  }

  /// Load the TFLite model and JSON assets asynchronously.
  Future<void> _initializeRecommender() async {
    try {
      await _recommender.initialize();
    } catch (e) {
      errorMessage.value = 'Failed to load recommendation model: $e';
    }
  }

  @override
  void onClose() {
    _recommender.dispose();
    nController.dispose();
    pController.dispose();
    kController.dispose();
    temperatureController.dispose();
    humidityController.dispose();
    phController.dispose();
    rainfallController.dispose();
    super.onClose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  /// Validate a numeric input field.
  String? validateField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  // ── Recommendation ────────────────────────────────────────────────────────

  /// Run TFLite inference with current form values and save to Firestore.
  Future<void> getRecommendation() async {
    if (!formKey.currentState!.validate()) return;

    if (!_recommender.isReady) {
      Get.snackbar(
        'Please wait',
        'Recommendation model is still loading…',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final input = CropInput(
        n: double.parse(nController.text.trim()),
        p: double.parse(pController.text.trim()),
        k: double.parse(kController.text.trim()),
        temperature: double.parse(temperatureController.text.trim()),
        humidity: double.parse(humidityController.text.trim()),
        ph: double.parse(phController.text.trim()),
        rainfall: double.parse(rainfallController.text.trim()),
      );

      final result = await _service.getRecommendations(
        input: input,
        userId: _userId,
      );

      currentRecommendation.value = result;

      // Navigate to results screen
      Get.toNamed('/crop-recommendation/results');
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── History ───────────────────────────────────────────────────────────────

  /// Load recommendation history for current user.
  Future<void> loadHistory() async {
    if (_userId.isEmpty) return;

    isHistoryLoading.value = true;
    try {
      final records = await _service.getHistory(_userId);
      history.assignAll(records);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load history',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isHistoryLoading.value = false;
    }
  }

  /// Set a specific recommendation for viewing details.
  void viewRecommendationDetail(RecommendationModel model) {
    currentRecommendation.value = model;
    Get.toNamed('/crop-recommendation/results');
  }

  /// Clear form fields.
  void clearForm() {
    nController.clear();
    pController.clear();
    kController.clear();
    temperatureController.clear();
    humidityController.clear();
    phController.clear();
    rainfallController.clear();
    errorMessage.value = '';
  }
}
