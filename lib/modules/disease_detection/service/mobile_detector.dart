import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class MobileDetector {
  static final MobileDetector instance = MobileDetector._();
  MobileDetector._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool isReady = false;

  Future<void> loadModel() async {
    try {
      // Labels load
      final raw = await rootBundle.loadString('assets/labels.txt');
      _labels = raw.trim().split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // TFLite model load
      _interpreter = await Interpreter.fromAsset(
        'assets/models/crop_model.tflite',
        options: InterpreterOptions()..threads = 4,
      );

      isReady = true;
      print('✅ Model ready! ${_labels.length} classes');
      print('Labels: $_labels');
    } catch (e) {
      print('❌ Model load error: $e');
      isReady = false;
    }
  }

  Future<Map<String, dynamic>> detect(XFile imageFile) async {
    if (!isReady || _interpreter == null) {
      return {'error': 'Model tayyar nahi, app restart karein'};
    }

    try {
      // Image read aur preprocess
      final bytes = await imageFile.readAsBytes();
      var rawImage = img.decodeImage(bytes);

      if (rawImage == null) {
        return {'error': 'Image read nahi ho saki'};
      }

      // 224x224 resize
      var resized = img.copyResize(rawImage, width: 224, height: 224);

      // Input tensor [1, 224, 224, 3] float32
      var input = List.generate(
        1,
            (_) => List.generate(
          224,
              (y) => List.generate(
            224,
                (x) {
              final pixel = resized.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      // Output tensor
      var output = List.filled(_labels.length, 0.0)
          .reshape([1, _labels.length]);

      // Run inference
      _interpreter!.run(input, output);

      // Best result
      List<double> scores = List<double>.from(output[0]);
      int maxIdx = scores.indexOf(
          scores.reduce((a, b) => a > b ? a : b));

      // Top 3
      var indexed = scores.asMap().entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      List<Map<String, String>> top3 = indexed.take(3).map((e) => {
        'disease': _labels[e.key],
        'confidence': (e.value * 100).toStringAsFixed(1),
      }).toList();

      return {
        'disease': _labels[maxIdx],
        'confidence': (scores[maxIdx] * 100).toStringAsFixed(1),
        'is_healthy': _labels[maxIdx].contains('Healthy'),
        'top3': top3,
      };
    } catch (e) {
      return {'error': 'Detection error: $e'};
    }
  }
}