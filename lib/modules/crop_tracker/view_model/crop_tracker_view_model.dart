import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/crop_model.dart';
import '../repositories/crop_repository.dart';

class CropTrackerViewModel extends GetxController {
  final ICropRepository _repo;

  CropTrackerViewModel({ICropRepository? repo})
      : _repo = repo ?? CropRepository();

  // ── State ──
  final RxList<CropRecord> crops = <CropRecord>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxString errorMessage = ''.obs;

  final _uuid = const Uuid();

  String get userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  bool get isGuest =>
      FirebaseAuth.instance.currentUser == null;

  // ── Computed ──
  List<CropRecord> get filteredCrops {
    switch (selectedFilter.value) {
      case 'active':
        return crops.where((c) => !c.isHarvested).toList();
      case 'harvested':
        return crops.where((c) => c.isHarvested).toList();
      default:
        return crops;
    }
  }

  double get totalExpenses =>
      crops.fold(0, (s, c) => s + c.totalExpenses);
  double get totalIncome =>
      crops.fold(0, (s, c) => s + (c.harvest?.totalIncome ?? 0));
  double get totalProfit => totalIncome - totalExpenses;
  int get activeCrops =>
      crops.where((c) => !c.isHarvested).length;

  @override
  void onInit() {
    super.onInit();
    loadCrops();
  }

  // ── LOAD ──
  Future<void> loadCrops() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _repo.getCrops(userId);
      crops.value = result;
    } catch (e) {
      errorMessage.value = 'Error loading: $e';
      _showError(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // ── ADD CROP ──
  Future<void> addCrop({
    required String cropName,
    required String cropType,
    required double areaAcres,
    required DateTime sowingDate,
    DateTime? expectedHarvestDate,
  }) async {
    isSaving.value = true;
    try {
      final crop = CropRecord(
        id: _uuid.v4(),
        cropName: cropName,
        cropType: cropType,
        areaAcres: areaAcres,
        sowingDate: sowingDate,
        expectedHarvestDate: expectedHarvestDate,
        expenses: const [],
        userId: userId,
        createdAt: DateTime.now(),
      );

      await _repo.addCrop(crop);
      crops.insert(0, crop);

      Get.back();
      _showSuccess('$cropName added successfully!');
    } catch (e) {
      _showError('Could not add: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ── UPDATE STAGE ──
  Future<void> updateStage(
      String cropId, CropStage stage) async {
    final idx = crops.indexWhere((c) => c.id == cropId);
    if (idx == -1) return;

    final updated = crops[idx].copyWith(currentStage: stage);
    crops[idx] = updated;
    crops.refresh();

    await _repo.updateCrop(updated);
  }

  // ── ADD EXPENSE ──
  Future<void> addExpense(
      String cropId, {
        required String category,
        required String description,
        required double amount,
        required DateTime date,
      }) async {
    isSaving.value = true;
    try {
      final idx = crops.indexWhere((c) => c.id == cropId);
      if (idx == -1) return;

      final expense = CropExpense(
        id: _uuid.v4(),
        category: category,
        description: description,
        amount: amount,
        date: date,
      );

      final updatedExpenses = [
        ...crops[idx].expenses,
        expense
      ];
      final updated =
      crops[idx].copyWith(expenses: updatedExpenses);

      crops[idx] = updated;
      crops.refresh();

      await _repo.updateCrop(updated);

      Get.back();
      _showSuccess('Expense added successfully!');
    } catch (e) {
      _showError('Could not add expense: $e');
    } finally {
      isSaving.value = false;
    }
  }
  // ── DELETE EXPENSE ──
  Future<void> deleteExpense(
      String cropId, String expenseId) async {
    final idx = crops.indexWhere((c) => c.id == cropId);
    if (idx == -1) return;

    final updatedExpenses = crops[idx]
        .expenses
        .where((e) => e.id != expenseId)
        .toList();

    final updated =
    crops[idx].copyWith(expenses: updatedExpenses);
    crops[idx] = updated;
    crops.refresh();

    await _repo.updateCrop(updated);

    Get.snackbar(
      'Deleted',
      'Expense deleted',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
    );
  }

// ── EDIT EXPENSE ──
  Future<void> editExpense(
      String cropId, {
        required String expenseId,
        required String newDescription,
        required double newAmount,
      }) async {
    final idx = crops.indexWhere((c) => c.id == cropId);
    if (idx == -1) return;

    final updatedExpenses = crops[idx].expenses.map((e) {
      if (e.id == expenseId) {
        return CropExpense(
          id: e.id,
          category: e.category,
          description: newDescription,
          amount: newAmount,
          date: e.date,
        );
      }
      return e;
    }).toList();

    final updated =
    crops[idx].copyWith(expenses: updatedExpenses);
    crops[idx] = updated;
    crops.refresh();

    await _repo.updateCrop(updated);

    Get.snackbar(
      ' Updated',
      'Expense updated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  // ── RECORD HARVEST ──
  Future<void> recordHarvest(
      String cropId, {
        required double yieldKg,
        required double pricePerKg,
        required DateTime harvestDate,
        required String notes,
      }) async {
    isSaving.value = true;
    try {
      final idx = crops.indexWhere((c) => c.id == cropId);
      if (idx == -1) return;

      final harvest = HarvestRecord(
        yieldKg: yieldKg,
        pricePerKg: pricePerKg,
        harvestDate: harvestDate,
        notes: notes,
      );

      final updated = crops[idx].copyWith(
        harvest: harvest,
        currentStage: CropStage.harvest,
      );

      crops[idx] = updated;
      crops.refresh();

      await _repo.updateCrop(updated);

      Get.back();
      Get.snackbar(
        ' Congratulations!',
        'Income: Rs ${harvest.totalIncome.toStringAsFixed(0)}',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _showError('Could not record harvest: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ── DELETE ──
  Future<void> deleteCrop(String cropId) async {
    try {
      await _repo.deleteCrop(cropId, userId);
      crops.removeWhere((c) => c.id == cropId);
      Get.snackbar(
        'Deleted',
        'Crop record deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _showError('Could not delete: $e');
    }
  }

  // ── FILTER ──
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void _showSuccess(String msg) => Get.snackbar(
    ' Success', msg,
    backgroundColor: Colors.green.shade100,
    colorText: Colors.green.shade800,
    snackPosition: SnackPosition.BOTTOM,
  );

  void _showError(String msg) => Get.snackbar(
    'Error', msg,
    backgroundColor: Colors.red.shade100,
    colorText: Colors.red.shade800,
    snackPosition: SnackPosition.BOTTOM,
  );
}