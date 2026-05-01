import 'dart:io';

import 'disease_detector.dart';

/// Facade for disease detection.
///
/// All inference is performed on-device via [DiseaseDetector].
/// Zero network calls are made during prediction.
class DiseaseService {
  bool get isReady => DiseaseDetector.instance.isReady;

  /// Warm up the TFLite interpreter and load JSON assets.
  Future<void> init() => DiseaseDetector.instance.initialize();

  /// Run on-device inference and return a [DiseaseResult].
  Future<DiseaseResult> detect(File imageFile) =>
      DiseaseDetector.instance.predict(imageFile);

  /// Release the native interpreter (call from dispose).
  void dispose() => DiseaseDetector.instance.dispose();
}