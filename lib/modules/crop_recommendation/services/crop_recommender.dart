import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/recommendation_model.dart';

/// On-device TFLite inference service for crop recommendation.
///
/// Lifecycle:
///   1. Call [initialize] once (e.g., in the controller's [onInit]).
///   2. Call [recommend] to run inference synchronously on the Dart side.
///   3. Call [dispose] in [onClose] to release the native interpreter.
class CropRecommender {
  Interpreter? _interpreter;
  Map<int, String> _labelMap = {};
  List<double> _mean = [];
  List<double> _scale = [];

  bool get isReady => _interpreter != null;

  // ── Asset paths ──────────────────────────────────────────────────────────

  static const String _modelPath = 'assets/models/crop_model.tflite';
  static const String _labelMapPath = 'assets/models/label_map.json';
  static const String _scalerPath = 'assets/models/scaler_params.json';

  // ── Initialization ────────────────────────────────────────────────────────

  /// Load interpreter and JSON support files from bundled assets.
  /// Must be awaited before calling [recommend].
  Future<void> initialize() async {
    await Future.wait([
      _loadInterpreter(),
      _loadLabelMap(),
      _loadScalerParams(),
    ]);
  }

  Future<void> _loadInterpreter() async {
    final options = InterpreterOptions()..threads = 2;
    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
  }

  Future<void> _loadLabelMap() async {
    final raw = await rootBundle.loadString(_labelMapPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _labelMap = decoded.map(
      (key, value) => MapEntry(int.parse(key), value as String),
    );
  }

  Future<void> _loadScalerParams() async {
    final raw = await rootBundle.loadString(_scalerPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _mean =
        (decoded['mean'] as List<dynamic>)
            .map((v) => (v as num).toDouble())
            .toList();
    _scale =
        (decoded['scale'] as List<dynamic>)
            .map((v) => (v as num).toDouble())
            .toList();
  }

  // ── Inference ─────────────────────────────────────────────────────────────

  /// Run TFLite inference on [input] and return the top-3 [CropResult]s,
  /// sorted descending by softmax confidence.
  ///
  /// Throws [StateError] if [initialize] has not been called yet.
  List<CropResult> recommend(CropInput input) {
    if (!isReady) {
      throw StateError('CropRecommender.initialize() must be called first.');
    }

    // ── 1. Normalise: (value − mean) / scale ──────────────────────────────
    final raw = [
      input.n,
      input.p,
      input.k,
      input.temperature,
      input.humidity,
      input.ph,
      input.rainfall,
    ];

    final normalized = List<double>.generate(raw.length, (i) {
      final s = _scale[i];
      return s == 0.0 ? 0.0 : (raw[i] - _mean[i]) / s;
    });

    // ── 2. Prepare tensors ────────────────────────────────────────────────
    // Input shape: [1, 7]
    final inputTensor = [normalized];

    // Output shape: [1, numClasses]
    final numClasses = _labelMap.length;
    final outputTensor = [List<double>.filled(numClasses, 0.0)];

    // ── 3. Run inference ──────────────────────────────────────────────────
    _interpreter!.run(inputTensor, outputTensor);

    final probabilities = outputTensor[0];

    // ── 4. Build indexed list, sort descending, take top-3 ───────────────
    final indexed = List<MapEntry<int, double>>.generate(
      numClasses,
      (i) => MapEntry(i, probabilities[i]),
    )..sort((a, b) => b.value.compareTo(a.value));

    final top3 = indexed.take(3).map((entry) {
      final cropName = _labelMap[entry.key] ?? 'Unknown';
      final score = double.parse(entry.value.toStringAsFixed(4));
      final pct = double.parse((entry.value * 100).toStringAsFixed(1));
      return CropResult(
        cropName: cropName,
        score: score,
        suitabilityPercentage: pct,
      );
    }).toList();

    return top3;
  }

  // ── Disposal ──────────────────────────────────────────────────────────────

  /// Release the native interpreter. Call from [GetxController.onClose].
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
