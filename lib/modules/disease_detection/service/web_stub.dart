// Web platform stub — TFLite is not supported on web.
// DiseaseService will not call this on web; it is here only to satisfy the
// conditional-import contract so the file compiles on all platforms.
import 'dart:io';

import 'disease_detector.dart';

class MobileDetector {
  static final MobileDetector instance = MobileDetector._();
  MobileDetector._();

  bool get isReady => false;
  Future<void> loadModel() async {}
  Future<DiseaseResult> detect(File imageFile) async =>
      throw UnsupportedError('TFLite is not supported on web.');
}