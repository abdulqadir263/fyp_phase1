import 'dart:io';

import 'disease_detector.dart';


class MobileDetector {
  static final MobileDetector instance = MobileDetector._();
  MobileDetector._();

  bool get isReady => DiseaseDetector.instance.isReady;

  Future<void> loadModel() => DiseaseDetector.instance.initialize();

  Future<DiseaseResult> detect(File imageFile) =>
      DiseaseDetector.instance.predict(imageFile);
}