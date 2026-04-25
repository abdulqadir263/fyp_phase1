import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/crop_model.dart';

class CropLocalService {
  static final CropLocalService instance = CropLocalService._();
  CropLocalService._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aasaan_kisaan_crops.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE crops (
        id          TEXT PRIMARY KEY,
        cropName    TEXT NOT NULL,
        cropType    TEXT NOT NULL,
        areaAcres   REAL NOT NULL,
        sowingDate  TEXT NOT NULL,
        expectedHarvestDate TEXT,
        currentStage INTEGER DEFAULT 0,
        expenses    TEXT DEFAULT '[]',
        harvest     TEXT,
        userId      TEXT NOT NULL,
        createdAt   TEXT NOT NULL,
        isSynced    INTEGER DEFAULT 0
      )
    ''');
  }

  // ── INSERT / UPDATE ──
  Future<void> upsertCrop(CropRecord crop,
      {bool isSynced = false}) async {
    final db = await database;
    await db.insert(
      'crops',
      {
        ..._toDb(crop),
        'isSynced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── GET ALL ──
  Future<List<CropRecord>> getCrops(String userId) async {
    final db = await database;
    final maps = await db.query(
      'crops',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map(_fromDb).toList();
  }

  // ── GET UNSYNCED ──
  Future<List<CropRecord>> getUnsyncedCrops(
      String userId) async {
    final db = await database;
    final maps = await db.query(
      'crops',
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return maps.map(_fromDb).toList();
  }

  // ── MARK SYNCED ──
  Future<void> markSynced(String cropId) async {
    final db = await database;
    await db.update(
      'crops',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [cropId],
    );
  }

  // ── DELETE ──
  Future<void> deleteCrop(String id) async {
    final db = await database;
    await db.delete(
      'crops',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── HELPERS ──
  Map<String, dynamic> _toDb(CropRecord c) => {
    'id': c.id,
    'cropName': c.cropName,
    'cropType': c.cropType,
    'areaAcres': c.areaAcres,
    'sowingDate': c.sowingDate.toIso8601String(),
    'expectedHarvestDate':
    c.expectedHarvestDate?.toIso8601String(),
    'currentStage': c.currentStage.index,
    'expenses':
    jsonEncode(c.expenses.map((e) => e.toMap()).toList()),
    'harvest':
    c.harvest != null ? jsonEncode(c.harvest!.toMap()) : null,
    'userId': c.userId,
    'createdAt': c.createdAt.toIso8601String(),
  };

  CropRecord _fromDb(Map<String, dynamic> m) => CropRecord(
    id: m['id'],
    cropName: m['cropName'],
    cropType: m['cropType'],
    areaAcres: m['areaAcres'],
    sowingDate: DateTime.parse(m['sowingDate']),
    expectedHarvestDate: m['expectedHarvestDate'] != null
        ? DateTime.parse(m['expectedHarvestDate'])
        : null,
    currentStage: CropStage.values[m['currentStage'] ?? 0],
    expenses:
    (jsonDecode(m['expenses'] ?? '[]') as List)
        .map((e) => CropExpense.fromMap(e))
        .toList(),
    harvest: m['harvest'] != null
        ? HarvestRecord.fromMap(jsonDecode(m['harvest']))
        : null,
    userId: m['userId'],
    createdAt: DateTime.parse(m['createdAt']),
  );
}