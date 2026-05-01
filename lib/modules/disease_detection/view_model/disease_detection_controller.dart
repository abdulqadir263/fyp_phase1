import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/disease_history_record.dart';
import '../repository/disease_repository.dart';
import '../service/disease_detector.dart';
import '../service/disease_service.dart';

/// GetX controller for the Disease Detection module.
///
/// Responsibilities:
///  - Initialise / dispose [DiseaseService] (TFLite).
///  - Run predictions and expose the current [DiseaseResult].
///  - Save results to Firestore via [DiseaseRepository].
///  - Load and expose detection history.
class DiseaseDetectionController extends GetxController {
  final DiseaseService _service = DiseaseService();
  final DiseaseRepository _repo = DiseaseRepository();

  // ── Observable state ───────────────────────────────────────────────────────

  final isModelReady = false.obs;
  final isDetecting = false.obs;
  final isSaving = false.obs;
  final isHistoryLoading = false.obs;
  final historyError = ''.obs;

  final Rx<DiseaseResult?> currentResult = Rx<DiseaseResult?>(null);
  final Rx<File?> currentImage = Rx<File?>(null);
  final RxList<DiseaseHistoryRecord> history = <DiseaseHistoryRecord>[].obs;
  final showUrdu = false.obs;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _initModel();
  }

  @override
  void onClose() {
    _service.dispose();
    super.onClose();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> _initModel() async {
    try {
      await _service.init();
      isModelReady.value = true;
    } catch (e) {
      Get.snackbar(
        'Model Error',
        'Could not load disease model: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Detection ──────────────────────────────────────────────────────────────

  /// Run on-device inference on [imageFile] and update [currentResult].
  Future<void> detect(File imageFile) async {
    isDetecting.value = true;
    currentResult.value = null;
    currentImage.value = imageFile;
    showUrdu.value = false;

    try {
      final result = await _service.detect(imageFile);
      currentResult.value = result;
      
      // Auto-save history after successful detection
      await saveCurrentResult();
    } catch (e) {
      Get.snackbar(
        'Detection Error',
        'Could not analyse image: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDetecting.value = false;
    }
  }

  // ── Save to history ────────────────────────────────────────────────────────

  /// Persist [currentResult] to Firestore and prepend it to [history].
  Future<void> saveCurrentResult() async {
    final result = currentResult.value;
    if (result == null) return;
    if (_userId.isEmpty) {
      Get.snackbar(
        'Not signed in',
        'Please log in to save results.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSaving.value = true;
    try {
      final record = DiseaseHistoryRecord(
        id: '',
        userId: _userId,
        diseaseName: result.diseaseName,
        diseaseNameUr: result.diseaseNameUr,
        confidence: result.confidence,
        severity: result.severity,
        severityUr: result.severityUr,
        description: result.description,
        descriptionUr: result.descriptionUr,
        treatment: result.treatment,
        treatmentUr: result.treatmentUr,
        prevention: result.prevention,
        preventionUr: result.preventionUr,
        farmerTip: result.farmerTip,
        farmerTipUr: result.farmerTipUr,
        createdAt: DateTime.now(),
      );

      final docId = await _repo.saveRecord(record);

      // Prepend to local history list so the UI updates immediately
      history.insert(
        0,
        DiseaseHistoryRecord(
          id: docId,
          userId: record.userId,
          diseaseName: record.diseaseName,
          diseaseNameUr: record.diseaseNameUr,
          confidence: record.confidence,
          severity: record.severity,
          severityUr: record.severityUr,
          description: record.description,
          descriptionUr: record.descriptionUr,
          treatment: record.treatment,
          treatmentUr: record.treatmentUr,
          prevention: record.prevention,
          preventionUr: record.preventionUr,
          farmerTip: record.farmerTip,
          farmerTipUr: record.farmerTipUr,
          createdAt: record.createdAt,
        ),
      );

      Get.snackbar(
        'Saved!',
        'Result saved to history.',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Save Failed',
        'Could not save result: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ── History ────────────────────────────────────────────────────────────────

  /// Load detection history for the current user from Firestore.
  Future<void> loadHistory() async {
    if (_userId.isEmpty) return;
    isHistoryLoading.value = true;
    historyError.value = '';
    try {
      final records = await _repo.fetchHistory(_userId);
      history.assignAll(records);
    } catch (e) {
      historyError.value = 'Failed to load history';
      Get.snackbar(
        'Error',
        'Could not load history.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isHistoryLoading.value = false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void clearResult() {
    currentResult.value = null;
    currentImage.value = null;
    showUrdu.value = false;
  }

  void toggleLanguage() => showUrdu.value = !showUrdu.value;
}
