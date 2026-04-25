import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mobile_detector.dart'
if (dart.library.html) 'web_stub.dart';

class DiseaseService {
  // Render.com URL — deploy hone ke baad update karna
  static const String _apiUrl =
      'https://aasaan-kisaan-api.onrender.com/predict';

  bool get isReady =>
      kIsWeb ? true : MobileDetector.instance.isReady;

  Future<void> init() async {
    if (!kIsWeb) {
      await MobileDetector.instance.loadModel();
    }
  }

  Future<Map<String, dynamic>> detect(XFile image) async {
    try {
      if (kIsWeb) {
        return await _detectViaApi(image);
      } else {
        return await MobileDetector.instance.detect(image);
      }
    } catch (e) {
      return {'error': 'Detection mein masla aya: $e'};
    }
  }

  // Web: FastAPI backend
  Future<Map<String, dynamic>> _detectViaApi(XFile image) async {
    final bytes = await image.readAsBytes();
    final request = http.MultipartRequest(
        'POST', Uri.parse(_apiUrl));
    request.files.add(
      http.MultipartFile.fromBytes(
          'file', bytes, filename: 'leaf.jpg'),
    );

    final response = await request.send()
        .timeout(const Duration(seconds: 60));
    final body = await response.stream.bytesToString();
    return json.decode(body);
  }
}