import 'dart:io';

import 'disease_detector.dart';

/// Mobile platform adapter — thin wrapper around [DiseaseDetector].
///
/// All inference, preprocessing, and label/solution lookup logic lives in
/// [DiseaseDetector]. This class exists so [DiseaseService] can use
/// conditional imports without changing the call site.
class MobileDetector {
  static final MobileDetector instance = MobileDetector._();
  MobileDetector._();

  bool get isReady => DiseaseDetector.instance.isReady;

  Future<void> loadModel() => DiseaseDetector.instance.initialize();

  Future<DiseaseResult> detect(File imageFile) =>
      DiseaseDetector.instance.predict(imageFile);
}