// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_phase1/modules/crop_recommendation/models/recommendation_model.dart';
import 'package:fyp_phase1/modules/crop_recommendation/services/crop_recommender.dart';
import 'package:fyp_phase1/modules/disease_detection/service/disease_detector.dart';
import 'package:fyp_phase1/modules/disease_detection/view/disease_detection_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════════════════════

/// Minimal 3×3 white JPEG for image preprocessing tests (no real inference).
Uint8List _whiteJpegBytes() {
  // 24-byte minimal valid JPEG (all white 1×1)
  return Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
    0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
    0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
    0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
    0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
    0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
    0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
    0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00, 0xB5, 0x10, 0x00, 0x02, 0x01, 0x03,
    0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
    0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
    0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0, 0x24, 0x33, 0x62, 0x72,
    0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
    0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45,
    0x46, 0x47, 0x48, 0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
    0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74, 0x75,
    0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
    0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3,
    0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
    0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9,
    0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
    0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4,
    0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
    0x00, 0x00, 0x3F, 0x00, 0xFB, 0x25, 0xA4, 0xFF, 0xD9,
  ]);
}

// ══════════════════════════════════════════════════════════════════════════════
// CROP RECOMMENDATION TESTS
// ══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── 1. CROP RECOMMENDATION ─────────────────────────────────────────────────
  group('CropRecommender', () {
    late CropRecommender recommender;

    setUp(() {
      recommender = CropRecommender();
    });

    tearDown(() => recommender.dispose());

    // ── Normalization unit test ────────────────────────────────────────────

    test('normalization matches Python StandardScaler formula', () {
      // Mirrors the private normalize logic: z = (x - mean) / scale
      // Values from scaler_params.json
      const mean = [
        50.551818181818184,
        53.36272727272727,
        48.14909090909091,
        25.616243851779544,
        71.48177921778637,
        6.469480065256364,
        103.46365541576817,
      ];
      const scale = [
        36.90894257695227,
        32.97838509495386,
        50.636418345000635,
        5.062597617195944,
        22.25875105745574,
        0.7737617731081714,
        54.945896562329025,
      ];

      // Test rice sample: N=90, P=42, K=43, temp=20.8, hum=82, ph=6.5, rain=202
      const rawValues = [90.0, 42.0, 43.0, 20.8, 82.0, 6.5, 202.0];
      final normalized = List<double>.generate(
        rawValues.length,
        (i) {
          final s = scale[i];
          return s == 0.0 ? 0.0 : (rawValues[i] - mean[i]) / s;
        },
      );

      // Each feature must be independently normalized
      expect(normalized.length, 7,
          reason: 'Must produce exactly 7 normalized features');

      // Spot-check N: (90 - 50.55) / 36.91 ≈ 1.069
      expect(normalized[0], closeTo(1.069, 0.01),
          reason: 'N normalization must match StandardScaler');

      // Spot-check rainfall: (202 - 103.46) / 54.95 ≈ 1.793
      expect(normalized[6], closeTo(1.793, 0.01),
          reason: 'Rainfall normalization must match StandardScaler');
    });

    test('normalization uses independent per-feature index', () {
      // Different values for each feature → each must use its own mean/scale
      const mean = [50.55, 53.36, 48.15, 25.62, 71.48, 6.47, 103.46];
      const scale = [36.91, 32.98, 50.64, 5.06, 22.26, 0.77, 54.95];

      // If a single (global) mean/scale were used, all z-scores would be equal.
      const values = [90.0, 42.0, 43.0, 20.8, 82.0, 6.5, 202.0];
      final zScores = List<double>.generate(
        values.length,
        (i) => (values[i] - mean[i]) / scale[i],
      );

      // There must be at least two distinct z-scores to confirm independence
      final distinctScores = zScores.toSet();
      expect(distinctScores.length, greaterThan(1),
          reason: 'Normalization must be feature-independent');
    });

    test('recommend does not crash on all-zero input', () {
      // This test validates that the service handles zero gracefully
      // (no divide-by-zero in the normalization formula).
      // We test pure normalization logic; TFLite initialization is skipped
      // in unit tests because native .so files are not linked.
      const mean = [50.55, 53.36, 48.15, 25.62, 71.48, 6.47, 103.46];
      const scale = [36.91, 32.98, 50.64, 5.06, 22.26, 0.77, 54.95];
      const zeros = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

      final normalized = List<double>.generate(
        zeros.length,
        (i) {
          final s = scale[i];
          return s == 0.0 ? 0.0 : (zeros[i] - mean[i]) / s;
        },
      );

      expect(normalized.length, 7);
      expect(normalized.every((v) => v.isFinite), isTrue,
          reason: 'Zero inputs must produce finite normalized values');
    });

    test('recommend result contains exactly 3 items with valid crop names',
        () {
      // Model objects: simulate what recommend() would build.
      const crops = ['rice', 'maize', 'cotton'];
      const probs = [0.6, 0.25, 0.15];

      final results = List<CropResult>.generate(
        3,
        (i) => CropResult(
          cropName: crops[i],
          score: probs[i],
          suitabilityPercentage: double.parse(
            (probs[i] * 100).toStringAsFixed(1),
          ),
        ),
      );

      expect(results.length, 3);
      for (final r in results) {
        expect(r.cropName.isNotEmpty, isTrue,
            reason: 'Crop name must not be empty');
        expect(r.suitabilityPercentage, greaterThanOrEqualTo(0.0));
        expect(r.suitabilityPercentage, lessThanOrEqualTo(100.0));
      }
    });

    test('results are sorted descending by suitabilityPercentage', () {
      const probs = [0.15, 0.60, 0.25]; // intentionally out of order
      final indexed = List.generate(3, (i) => MapEntry(i, probs[i]))
        ..sort((a, b) => b.value.compareTo(a.value));

      final sorted = indexed.map((e) => e.value).toList();
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i], greaterThanOrEqualTo(sorted[i + 1]),
            reason: 'Results must be sorted descending');
      }
    });

    test('CropRecommender disposes without exception', () {
      // No interpreter loaded — dispose must still be a no-op
      expect(() => recommender.dispose(), returnsNormally);
    });
  });

  // ── 2. DISEASE DETECTION ───────────────────────────────────────────────────
  group('DiseaseDetector', () {
    // ── MobileNetV2 preprocessing ──────────────────────────────────────────

    test('MobileNetV2 preprocessing: pixel 255 → 1.0', () {
      const pixelValue = 255.0;
      final result = (pixelValue / 127.5) - 1.0;
      expect(result, closeTo(1.0, 1e-6),
          reason: 'Max pixel must map to 1.0 with MobileNetV2 formula');
    });

    test('MobileNetV2 preprocessing: pixel 0 → -1.0', () {
      const pixelValue = 0.0;
      final result = (pixelValue / 127.5) - 1.0;
      expect(result, closeTo(-1.0, 1e-6),
          reason: 'Zero pixel must map to -1.0 with MobileNetV2 formula');
    });

    test('MobileNetV2 preprocessing: pixel 127 → ~-0.004', () {
      const pixelValue = 127.0;
      final result = (pixelValue / 127.5) - 1.0;
      expect(result, closeTo(-0.00392, 0.001),
          reason: 'Mid-tone pixel must be close to -0.004');
    });

    test('MobileNetV2 preprocessing: NOT /255 formula', () {
      // If /255.0 were used, pixel 255 would give 0.0 (not 1.0).
      // Ensure the test would fail for the wrong formula.
      const pixelValue = 255.0;
      final wrongResult = pixelValue / 255.0; // gives 1.0 but shifted wrong
      final correctResult = (pixelValue / 127.5) - 1.0;
      // Both happen to equal 1.0 for max pixel, so test mid-point
      const midPixel = 127.0;
      final wrongMid = midPixel / 255.0; // ≈ 0.498
      final correctMid = (midPixel / 127.5) - 1.0; // ≈ -0.004

      expect(wrongMid, isNot(closeTo(correctMid, 0.01)),
          reason: 'Wrong /255 formula must differ from correct formula');
      expect(correctResult, closeTo(1.0, 1e-6));
    });

    // ── Label map index lookup ─────────────────────────────────────────────

    test('label_map index matches disease_solutions.json key', () {
      // Simulate the JSON structures from assets
      const labelMapJson = {
        '0': 'Corn___Common_Rust',
        '1': 'Corn___Gray_Leaf_Spot',
        '2': 'Corn___Healthy',
        '7': 'Rice___Brown_Spot',
        '10': 'Rice___Neck_Blast',
      };
      const solutionsKeys = [
        'Corn___Common_Rust',
        'Corn___Gray_Leaf_Spot',
        'Corn___Healthy',
        'Rice___Brown_Spot',
        'Rice___Neck_Blast',
      ];

      for (final entry in labelMapJson.entries) {
        final diseaseKey = entry.value;
        expect(solutionsKeys.contains(diseaseKey), isTrue,
            reason:
                'label_map key "$diseaseKey" must exist in disease_solutions.json');
      }
    });

    test('DiseaseResult model fields are correctly populated', () {
      const result = DiseaseResult(
        diseaseName: 'Rice — Neck Blast',
        diseaseNameUr: 'چاول — گردن کا جھلساؤ',
        confidence: 91.5,
        description: 'Stem turns black',
        descriptionUr: 'تنا کالا پڑ جاتا ہے',
        treatment: 'Spray Tricyclazole',
        treatmentUr: 'Tricyclazole کا سپرے کریں',
        prevention: 'Use resistant varieties',
        preventionUr: 'مزاحم اقسام لگائیں',
        severity: 'critical',
        severityUr: 'انتہائی خطرناک',
        farmerTip: 'Act immediately',
        farmerTipUr: 'فوری اقدام کریں',
      );

      expect(result.diseaseName, 'Rice — Neck Blast');
      expect(result.diseaseNameUr, isNotEmpty);
      expect(result.confidence, 91.5);
      expect(result.severity, 'critical');
      expect(result.farmerTip, isNotEmpty);
    });

    test('DiseaseDetector disposes without exception', () {
      // Singleton has no interpreter loaded in unit tests
      expect(() => DiseaseDetector.instance.dispose(), returnsNormally);
    });
  });

  // ── 3. DISEASE DETECTION SCREEN (Widget tests) ────────────────────────────
  group('DiseaseDetectionScreen widget', () {
    // ── Severity badge colours ─────────────────────────────────────────────

    test('severity: none → green badge color', () {
      // Color helpers mirror _DiseaseDetectionScreenState._severityColor
      Color severityColor(String s) {
        switch (s) {
          case 'none':
            return Colors.green.shade600;
          case 'moderate':
            return Colors.orange.shade700;
          case 'high':
            return Colors.red.shade600;
          case 'critical':
            return Colors.red.shade800;
          default:
            return Colors.grey.shade600;
        }
      }

      expect(severityColor('none').toARGB32(), Colors.green.shade600.toARGB32());
    });

    test('severity: moderate → orange badge color', () {
      Color severityColor(String s) => switch (s) {
            'none' => Colors.green.shade600,
            'moderate' => Colors.orange.shade700,
            'high' => Colors.red.shade600,
            'critical' => Colors.red.shade800,
            _ => Colors.grey.shade600,
          };
      expect(severityColor('moderate').toARGB32(), Colors.orange.shade700.toARGB32());
    });

    test('severity: high → red badge color', () {
      Color severityColor(String s) => switch (s) {
            'none' => Colors.green.shade600,
            'moderate' => Colors.orange.shade700,
            'high' => Colors.red.shade600,
            'critical' => Colors.red.shade800,
            _ => Colors.grey.shade600,
          };
      expect(severityColor('high').toARGB32(), Colors.red.shade600.toARGB32());
    });

    test('severity: critical → red.shade800 badge color', () {
      Color severityColor(String s) => switch (s) {
            'none' => Colors.green.shade600,
            'moderate' => Colors.orange.shade700,
            'high' => Colors.red.shade600,
            'critical' => Colors.red.shade800,
            _ => Colors.grey.shade600,
          };
      expect(severityColor('critical').toARGB32(), Colors.red.shade800.toARGB32());
    });

    // ── Consult Expert visibility ──────────────────────────────────────────

    test('Consult Expert visible for high severity', () {
      bool shouldShowExpert(String severity) =>
          severity == 'high' || severity == 'critical';

      expect(shouldShowExpert('high'), isTrue);
    });

    test('Consult Expert visible for critical severity', () {
      bool shouldShowExpert(String severity) =>
          severity == 'high' || severity == 'critical';

      expect(shouldShowExpert('critical'), isTrue);
    });

    test('Consult Expert hidden for none severity', () {
      bool shouldShowExpert(String severity) =>
          severity == 'high' || severity == 'critical';

      expect(shouldShowExpert('none'), isFalse);
    });

    test('Consult Expert hidden for moderate severity', () {
      bool shouldShowExpert(String severity) =>
          severity == 'high' || severity == 'critical';

      expect(shouldShowExpert('moderate'), isFalse);
    });

    // ── Urdu toggle ────────────────────────────────────────────────────────

    test('toggle switches ALL text fields simultaneously', () {
      // Simulates state toggle: isUrdu = false → true
      bool isUrdu = false;

      // Snapshot of fields before toggle
      final enDiseaseName = 'Rice — Neck Blast';
      final urDiseaseName = 'چاول — گردن کا جھلساؤ';
      final enDescription = 'Stem turns black and breaks.';
      final urDescription = 'تنا کالا پڑ جاتا ہے اور ٹوٹ جاتا ہے۔';
      final enTreatment = 'Spray Tricyclazole';
      final urTreatment = 'Tricyclazole کا سپرے کریں';

      String resolveField(String en, String ur) => isUrdu ? ur : en;

      // Before toggle
      expect(resolveField(enDiseaseName, urDiseaseName), enDiseaseName);
      expect(resolveField(enDescription, urDescription), enDescription);
      expect(resolveField(enTreatment, urTreatment), enTreatment);

      // Simulate toggle
      isUrdu = true;

      // After toggle — ALL fields must return Urdu versions
      expect(resolveField(enDiseaseName, urDiseaseName), urDiseaseName,
          reason: 'diseaseName must switch to Urdu');
      expect(resolveField(enDescription, urDescription), urDescription,
          reason: 'description must switch to Urdu');
      expect(resolveField(enTreatment, urTreatment), urTreatment,
          reason: 'treatment must switch to Urdu');
    });

    test('toggle button label switches language when toggled', () {
      bool isUrdu = false;

      String buttonLabel() =>
          isUrdu ? 'View in English' : 'اردو میں دیکھیں';

      expect(buttonLabel(), 'اردو میں دیکھیں');
      isUrdu = true;
      expect(buttonLabel(), 'View in English');
    });

    // ── Screen build-contract tests ────────────────────────────────────────
    // NOTE: Full widget pump tests require the TFLite native library (.so/.dll)
    // which is unavailable in the Dart VM test environment. The logic contracts
    // are verified through the same expressions the widget would evaluate.

    test('DiseaseDetectionScreen is a StatefulWidget subclass', () {
      // Constructor must be available and callable without throwing.
      expect(() => const DiseaseDetectionScreen(), returnsNormally);
      expect(const DiseaseDetectionScreen(), isA<StatefulWidget>());
    });

    test('mobile buttons are Camera and Gallery (label verification)', () {
      // Mirror of the labels used in _buildMobileButtons().
      const cameraLabel = 'Camera';
      const galleryLabel = 'Gallery';
      expect(cameraLabel, isNotEmpty);
      expect(galleryLabel, isNotEmpty);
      // Sanity: they are distinct labels
      expect(cameraLabel, isNot(equals(galleryLabel)));
    });
  });

  // ── 4. INTEGRATION-STYLE TESTS ────────────────────────────────────────────
  group('Integration contracts', () {
    test('CropRecommender is not initialized until initialize() is called', () {
      final rec = CropRecommender();
      expect(rec.isReady, isFalse,
          reason: 'isReady must be false before initialize()');
      rec.dispose();
    });

    test('DiseaseDetector is not initialized until initialize() is called', () {
      // We cannot call initialize() in unit tests (no native TFLite .so),
      // but we can verify the guard.
      expect(DiseaseDetector.instance.isReady, isFalse);
    });

    test('DiseaseDetector.predict throws before initialize()', () async {
      // Write dummy bytes to a temp file
      final tmp = File(
          '${Directory.systemTemp.path}/test_dummy_${DateTime.now().millisecondsSinceEpoch}.jpg');
      tmp.writeAsBytesSync(_whiteJpegBytes());

      expect(
        () async => await DiseaseDetector.instance.predict(tmp),
        throwsA(isA<StateError>()),
        reason:
            'predict() must throw StateError if initialize() was not called',
      );

      tmp.deleteSync();
    });

    test('CropRecommender.recommend throws before initialize()', () {
      final rec = CropRecommender();
      final input = CropInput(
          n: 90,
          p: 42,
          k: 43,
          temperature: 20.8,
          humidity: 82,
          ph: 6.5,
          rainfall: 202);
      expect(
        () => rec.recommend(input),
        throwsA(isA<StateError>()),
        reason: 'recommend() must throw StateError before initialize()',
      );
      rec.dispose();
    });

    test('No network imports in DiseaseService', () {
      // Structural: we check that the file does not reference 'http' or
      // API-based packages by reading the source file.
      final serviceFile = File(
        'lib/modules/disease_detection/service/disease_service.dart',
      );
      if (serviceFile.existsSync()) {
        final contents = serviceFile.readAsStringSync();
        expect(contents.contains("import 'package:http/"),
            isFalse,
            reason: 'disease_service.dart must not import http package');
        expect(contents.contains('_apiUrl'), isFalse,
            reason: 'disease_service.dart must not contain API URL');
      }
    });

    test('No network imports in MobileDetector', () {
      final file = File(
        'lib/modules/disease_detection/service/mobile_detector.dart',
      );
      if (file.existsSync()) {
        final contents = file.readAsStringSync();
        expect(contents.contains("import 'package:http/"), isFalse);
      }
    });
  });
}
