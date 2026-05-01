import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// ── Data model ────────────────────────────────────────────────────────────────

/// Holds every field returned from a disease prediction, in both English and Urdu.
class DiseaseResult {
  final String diseaseName;
  final String diseaseNameUr;
  final double confidence; // 0.0 – 100.0
  final String description;
  final String descriptionUr;
  final String treatment;
  final String treatmentUr;
  final String prevention;
  final String preventionUr;
  final String severity; // "none" | "moderate" | "high" | "critical"
  final String severityUr;
  final String farmerTip;
  final String farmerTipUr;

  const DiseaseResult({
    required this.diseaseName,
    required this.diseaseNameUr,
    required this.confidence,
    required this.description,
    required this.descriptionUr,
    required this.treatment,
    required this.treatmentUr,
    required this.prevention,
    required this.preventionUr,
    required this.severity,
    required this.severityUr,
    required this.farmerTip,
    required this.farmerTipUr,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

/// On-device EfficientNetB0 disease detection service.
///
/// Lifecycle:
///   1. Call [initialize] once (e.g., in the screen's [initState]).
///   2. Call [predict] to run inference on a [File].
///   3. Call [dispose] when the widget is removed from the tree.
class DiseaseDetector {
  static final DiseaseDetector instance = DiseaseDetector._();
  DiseaseDetector._();

  Interpreter? _interpreter;
  Map<int, String> _labelMap = {};
  Map<String, dynamic> _solutions = {};

  bool get isReady => _interpreter != null;

  // ── Asset paths ────────────────────────────────────────────────────────────

  static const String _modelPath =
      'assets/models/disease_detection/disease_model.tflite';
  static const String _labelMapPath =
      'assets/models/disease_detection/label_map.json';
  static const String _solutionsPath =
      'assets/models/disease_detection/disease_solutions.json';

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Load interpreter, label map, and disease solutions from bundled assets.
  Future<void> initialize() async {
    await Future.wait([
      _loadInterpreter(),
      _loadLabelMap(),
      _loadSolutions(),
    ]);
  }

  Future<void> _loadInterpreter() async {
    final options = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
  }

  Future<void> _loadLabelMap() async {
    final raw = await rootBundle.loadString(_labelMapPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _labelMap = decoded.map(
          (key, value) => MapEntry(int.parse(key), value as String),
    );
  }

  Future<void> _loadSolutions() async {
    final raw = await rootBundle.loadString(_solutionsPath);
    _solutions = jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Inference ──────────────────────────────────────────────────────────────

  /// Run EfficientNetB0 inference on [imageFile] and return a [DiseaseResult].
  ///
  /// Preprocessing: raw pixel values in range [0, 255] — the EfficientNetB0
  /// model includes an internal Rescaling layer that handles normalisation.
  /// Do NOT pre-normalise here; doing so causes double-preprocessing and
  /// makes the model predict the same class for every input.
  ///
  /// Input tensor shape : [1, 224, 224, 3] float32  (values 0–255)
  /// Output tensor shape: [1, numClasses]  float32  (softmax probabilities)
  Future<DiseaseResult> predict(File imageFile) async {
    if (!isReady) {
      throw StateError('DiseaseDetector.initialize() must be called first.');
    }

    // ── 1. Decode + resize ──────────────────────────────────────────────────
    final bytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(bytes);
    if (rawImage == null) {
      throw Exception('Could not decode image.');
    }
    final resized = img.copyResize(rawImage, width: 224, height: 224);

    // ── 2. Build [1, 224, 224, 3] input ─────────────────────────────────────
    // EfficientNetB0 contains an internal Rescaling layer trained to expect
    // raw uint8-range floats (0–255). Passing already-normalised values
    // (-1 to 1) would be rescaled a second time, producing garbage outputs.
    final inputTensor = List.generate(
      1,
          (_) => List.generate(
        224,
            (y) => List.generate(
          224,
              (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble(), // 0–255, no normalisation
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );

    // ── 3. Run inference ────────────────────────────────────────────────────
    final numClasses = _labelMap.length;
    final outputTensor = [List<double>.filled(numClasses, 0.0)];
    _interpreter!.run(inputTensor, outputTensor);

    final probabilities = outputTensor[0];

    // ── 4. Find top class ───────────────────────────────────────────────────
    int topIdx = 0;
    double topProb = probabilities[0];
    for (int i = 1; i < numClasses; i++) {
      if (probabilities[i] > topProb) {
        topProb = probabilities[i];
        topIdx = i;
      }
    }

    final confidence = topProb * 100.0;
    final diseaseKey = _labelMap[topIdx] ?? 'Unknown';

    // ── 5. Look up solutions ────────────────────────────────────────────────
    final sol =
        (_solutions[diseaseKey] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return DiseaseResult(
      diseaseName: sol['display_name'] as String? ?? diseaseKey,
      diseaseNameUr: sol['display_name_ur'] as String? ?? diseaseKey,
      confidence: confidence,
      description: sol['description'] as String? ?? '',
      descriptionUr: sol['description_ur'] as String? ?? '',
      treatment: sol['treatment'] as String? ?? '',
      treatmentUr: sol['treatment_ur'] as String? ?? '',
      prevention: sol['prevention'] as String? ?? '',
      preventionUr: sol['prevention_ur'] as String? ?? '',
      severity: sol['severity'] as String? ?? 'none',
      severityUr: sol['severity_ur'] as String? ?? '',
      farmerTip: sol['farmer_tip'] as String? ?? '',
      farmerTipUr: sol['farmer_tip_ur'] as String? ?? '',
    );
  }

  // ── Disposal ───────────────────────────────────────────────────────────────

  /// Release the native interpreter. Call when the owning widget is disposed.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}