import 'package:cloud_firestore/cloud_firestore.dart';

enum CropStage {
  sowing,
  germination,
  vegetative,
  flowering,
  ripening,
  harvest,
}

extension CropStageExt on CropStage {
  String get nameEn {
    switch (this) {
      case CropStage.sowing: return 'Sowing';
      case CropStage.germination: return 'Germination';
      case CropStage.vegetative: return 'Vegetative';
      case CropStage.flowering: return 'Flowering';
      case CropStage.ripening: return 'Ripening';
      case CropStage.harvest: return 'Harvest';
    }
  }

  String get nameUr {
    switch (this) {
      case CropStage.sowing: return 'بیج بونا';
      case CropStage.germination: return 'انکرن';
      case CropStage.vegetative: return 'نشوونما';
      case CropStage.flowering: return 'پھول';
      case CropStage.ripening: return 'پکنا';
      case CropStage.harvest: return 'کٹائی';
    }
  }

  String get emoji {
    switch (this) {
      case CropStage.sowing: return '🌱';
      case CropStage.germination: return '🌿';
      case CropStage.vegetative: return '🍃';
      case CropStage.flowering: return '🌸';
      case CropStage.ripening: return '🌾';
      case CropStage.harvest: return '✅';
    }
  }
}

class CropExpense {
  final String id;
  final String category;
  final String description;
  final double amount;
  final DateTime date;

  const CropExpense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory CropExpense.fromMap(Map<String, dynamic> map) => CropExpense(
    id: map['id'] ?? '',
    category: map['category'] ?? '',
    description: map['description'] ?? '',
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date']),
  );
}

class HarvestRecord {
  final double yieldKg;
  final double pricePerKg;
  final DateTime harvestDate;
  final String notes;

  const HarvestRecord({
    required this.yieldKg,
    required this.pricePerKg,
    required this.harvestDate,
    required this.notes,
  });

  double get totalIncome => yieldKg * pricePerKg;

  Map<String, dynamic> toMap() => {
    'yieldKg': yieldKg,
    'pricePerKg': pricePerKg,
    'harvestDate': harvestDate.toIso8601String(),
    'notes': notes,
  };

  factory HarvestRecord.fromMap(Map<String, dynamic> map) => HarvestRecord(
    yieldKg: (map['yieldKg'] as num).toDouble(),
    pricePerKg: (map['pricePerKg'] as num).toDouble(),
    harvestDate: DateTime.parse(map['harvestDate']),
    notes: map['notes'] ?? '',
  );
}

class CropRecord {
  final String id;
  final String cropName;
  final String cropType;
  final double areaAcres;
  final DateTime sowingDate;
  final DateTime? expectedHarvestDate;
  final CropStage currentStage;
  final List<CropExpense> expenses;
  final HarvestRecord? harvest;
  final String userId;
  final DateTime createdAt;

  const CropRecord({
    required this.id,
    required this.cropName,
    required this.cropType,
    required this.areaAcres,
    required this.sowingDate,
    this.expectedHarvestDate,
    this.currentStage = CropStage.sowing,
    this.expenses = const [],
    this.harvest,
    required this.userId,
    required this.createdAt,
  });

  // Computed
  double get totalExpenses =>
      expenses.fold(0, (sum, e) => sum + e.amount);
  double get netProfit =>
      (harvest?.totalIncome ?? 0) - totalExpenses;
  bool get isHarvested => currentStage == CropStage.harvest;
  int get daysInField =>
      DateTime.now().difference(sowingDate).inDays;

  // CopyWith — immutable update ke liye
  CropRecord copyWith({
    String? id,
    String? cropName,
    String? cropType,
    double? areaAcres,
    DateTime? sowingDate,
    DateTime? expectedHarvestDate,
    CropStage? currentStage,
    List<CropExpense>? expenses,
    HarvestRecord? harvest,
    String? userId,
    DateTime? createdAt,
  }) =>
      CropRecord(
        id: id ?? this.id,
        cropName: cropName ?? this.cropName,
        cropType: cropType ?? this.cropType,
        areaAcres: areaAcres ?? this.areaAcres,
        sowingDate: sowingDate ?? this.sowingDate,
        expectedHarvestDate:
        expectedHarvestDate ?? this.expectedHarvestDate,
        currentStage: currentStage ?? this.currentStage,
        expenses: expenses ?? this.expenses,
        harvest: harvest ?? this.harvest,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'cropName': cropName,
    'cropType': cropType,
    'areaAcres': areaAcres,
    'sowingDate': sowingDate.toIso8601String(),
    'expectedHarvestDate': expectedHarvestDate?.toIso8601String(),
    'currentStage': currentStage.index,
    'expenses': expenses.map((e) => e.toMap()).toList(),
    'harvest': harvest?.toMap(),
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CropRecord.fromMap(Map<String, dynamic> map) => CropRecord(
    id: map['id'] ?? '',
    cropName: map['cropName'] ?? '',
    cropType: map['cropType'] ?? '',
    areaAcres: (map['areaAcres'] as num).toDouble(),
    sowingDate: DateTime.parse(map['sowingDate']),
    expectedHarvestDate: map['expectedHarvestDate'] != null
        ? DateTime.parse(map['expectedHarvestDate'])
        : null,
    currentStage:
    CropStage.values[map['currentStage'] ?? 0],
    expenses: (map['expenses'] as List? ?? [])
        .map((e) => CropExpense.fromMap(e))
        .toList(),
    harvest: map['harvest'] != null
        ? HarvestRecord.fromMap(map['harvest'])
        : null,
    userId: map['userId'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
  );

  factory CropRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CropRecord.fromMap({...data, 'id': doc.id});
  }
}