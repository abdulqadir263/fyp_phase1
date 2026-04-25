// Web platform pe MobileDetector ki jagah yeh use hoga
import 'package:image_picker/image_picker.dart';

class MobileDetector {
  static final MobileDetector instance = MobileDetector._();
  MobileDetector._();
  bool isReady = false;
  Future<void> loadModel() async {}
  Future<Map<String, dynamic>> detect(XFile image) async => {};
}