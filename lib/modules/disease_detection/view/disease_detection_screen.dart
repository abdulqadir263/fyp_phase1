import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../service/disease_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() =>
      _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState
    extends State<DiseaseDetectionScreen> {
  final DiseaseService _service = DiseaseService();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  Map<String, dynamic>? _result;
  bool _loading = false;
  bool _modelReady = false;
  String _loadingMsg = 'Model load ho raha hai...';

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    await _service.init();
    if (mounted) {
      setState(() {
        _modelReady = true;
        _loadingMsg = '';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked == null) return;

      setState(() {
        _pickedImage = picked;
        _loading = true;
        _result = null;
        _loadingMsg = kIsWeb
            ? 'Server se connect ho raha hai...'
            : 'AI analyze kar raha hai...';
      });

      final result = await _service.detect(picked);

      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
          _loadingMsg = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMsg = '';
        });
        Get.snackbar(
          'Masla',
          'Image nahi li ja saki: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  // "Rice___Leaf_Blast" → "Rice — Leaf Blast"
  String _readable(String raw) =>
      raw.replaceAll('___', ' — ').replaceAll('_', ' ');

  String _cropUrdu(String disease) {
    if (disease.startsWith('Rice')) return 'Chawal (Rice)';
    if (disease.startsWith('Corn')) return 'Makka (Corn)';
    if (disease.startsWith('Wheat')) return 'Gehun (Wheat)';
    if (disease.startsWith('Potato')) return 'Aloo (Potato)';
    return 'Fasal';
  }

  Color _cropColor(String disease) {
    if (disease.startsWith('Rice')) return Colors.amber.shade700;
    if (disease.startsWith('Corn')) return Colors.yellow.shade800;
    if (disease.startsWith('Wheat')) return Colors.orange.shade700;
    if (disease.startsWith('Potato')) return Colors.brown.shade400;
    return AppConstants.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppConstants.primaryGreen,
        title: const Text(
          'Disease Detection',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model loading
            if (!_modelReady) _buildStatusBar(),

            // Info card
            _buildInfoCard(),
            const SizedBox(height: 16),

            // Image preview
            _buildImagePreview(),
            const SizedBox(height: 16),

            // Buttons
            kIsWeb ? _buildWebButton() : _buildMobileButtons(),
            const SizedBox(height: 20),

            // Loading
            if (_loading) _buildLoadingWidget(),

            // Result
            if (_result != null && !_loading)
              _buildResultCard(_result!),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Status Bar ──
  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(children: [
        SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange.shade700),
        ),
        const SizedBox(width: 10),
        Text(
          _loadingMsg,
          style: TextStyle(
              color: Colors.orange.shade800, fontSize: 13),
        ),
      ]),
    );
  }

  // ── Info Card ──
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppConstants.primaryGreen.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.tips_and_updates,
            color: AppConstants.primaryGreen, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            kIsWeb
                ? 'Laptop se fasal ki saaf image upload karein (Rice, Corn, Wheat, Potato)'
                : 'Camera se patte ki photo lo — Rice, Makka, Gehun, Aloo detect hogi',
            style: TextStyle(
                color: AppConstants.primaryGreen,
                fontSize: 13,
                height: 1.4),
          ),
        ),
      ]),
    );
  }

  // ── Image Preview ──
  Widget _buildImagePreview() {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _pickedImage == null
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined,
              size: 70,
              color: AppConstants.primaryGreen
                  .withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            kIsWeb
                ? 'Upload ki image yahan dikhegi'
                : 'Li hui photo yahan dikhegi',
            style: TextStyle(
                color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      )
          : Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: kIsWeb
                ? Image.network(
              _pickedImage!.path,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
                : Image.file(
              File(_pickedImage!.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Retake button
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => setState(() {
                _pickedImage = null;
                _result = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Web Button ──
  Widget _buildWebButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _modelReady
            ? () => _pickImage(ImageSource.gallery)
            : null,
        icon: const Icon(Icons.upload_file),
        label: Text(
          _modelReady ? 'Image Upload karein' : 'Loading...',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Mobile Buttons ──
  Widget _buildMobileButtons() {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: _modelReady
              ? () => _pickImage(ImageSource.camera)
              : null,
          icon: const Icon(Icons.camera_alt, size: 20),
          label: const Text('Camera',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryGreen,
            disabledForegroundColor: Colors.grey,
            side: BorderSide(
              color: _modelReady
                  ? AppConstants.primaryGreen
                  : Colors.grey.shade300,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _modelReady
              ? () => _pickImage(ImageSource.gallery)
              : null,
          icon: const Icon(Icons.photo_library, size: 20),
          label: const Text('Gallery',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  // ── Loading Widget ──
  Widget _buildLoadingWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          CircularProgressIndicator(
              color: AppConstants.primaryGreen),
          const SizedBox(height: 10),
          Text(
            _loadingMsg,
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 4),
            Text(
              '(Pehli baar 30-50 seconds lag sakti hai)',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── Result Card ──
  Widget _buildResultCard(Map<String, dynamic> result) {
    // Error
    if (result.containsKey('error')) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(result['error'].toString(),
                style: TextStyle(color: Colors.red.shade700)),
          ),
        ]),
      );
    }

    final String disease = result['disease'] ?? 'Unknown';
    final double confidence =
        double.tryParse(result['confidence'].toString()) ?? 0;
    final bool isHealthy = disease.contains('Healthy');
    final List top3 = result['top3'] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
          isHealthy ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHealthy
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHealthy
                      ? Icons.check_rounded
                      : Icons.bug_report_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Crop badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _cropColor(disease)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _cropUrdu(disease),
                        style: TextStyle(
                          fontSize: 11,
                          color: _cropColor(disease),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _readable(disease),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isHealthy
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Confidence bar ──
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Confidence',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13)),
                    Text(
                      '${result['confidence']}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color:
                        isHealthy ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: isHealthy ? Colors.green : Colors.red,
                    minHeight: 8,
                  ),
                ),

                // ── Top 3 results ──
                if (top3.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Doosri possibilities:',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12)),
                  const SizedBox(height: 6),
                  ...top3.skip(1).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          _readable(item['disease'] ?? ''),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600),
                        ),
                      ),
                      Text(
                        '${item['confidence']}%',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500),
                      ),
                    ]),
                  )),
                ],

                // ── Treatment ──
                if (!isHealthy) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.healing,
                        color: AppConstants.primaryGreen,
                        size: 18),
                    const SizedBox(width: 6),
                    Text('Ilaaj ki Tavsiya',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 15,
                        )),
                  ]),
                  const SizedBox(height: 10),
                  ..._getTreatment(disease).map(
                        (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(step,
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                    fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Appointment button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.primaryGreen,
                        side: BorderSide(
                            color: AppConstants.primaryGreen),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                      onPressed: () =>
                          Get.toNamed(AppRoutes.APPOINTMENTS),
                      icon: const Icon(Icons.calendar_today,
                          size: 18),
                      label: const Text(
                          'Expert se Appointment Lo'),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Retry
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _pickedImage = null;
                      _result = null;
                    }),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Dobara Try Karein'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTreatment(String disease) {
    const map = {
      'Corn___Common_Rust': [
        'Mancozeb ya Azoxystrobin spray karein',
        'Infected patte hata dein',
        'Resistant hybrid agle season lagayen',
      ],
      'Corn___Gray_Leaf_Spot': [
        'Propiconazole fungicide use karein',
        'Fasal rotation apnayen',
        'Purani fasal ke baqi hisse hata dein',
      ],
      'Corn___Northern_Leaf_Blight': [
        'Tebuconazole spray karein',
        'Nitrogen fertilizer balance karein',
        'Resistant seed agle season use karein',
      ],
      'Potato___Early_Blight': [
        'Chlorothalonil ya Mancozeb spray karein',
        'Pani seedha jad pe dein paton pe na',
        'Infected patte foran hatayen',
      ],
      'Potato___Late_Blight': [
        'Metalaxyl + Mancozeb FORAN spray karein',
        'Infected plants nikaal kar jalayen',
        'Barish ke mausam mein zyada dhyan rakhein',
      ],
      'Rice___Brown_Spot': [
        'Mancozeb ya Tricyclazole spray karein',
        'Potassium fertilizer barhayen',
        'Agle season seed treatment karein',
      ],
      'Rice___Leaf_Blast': [
        'Tricyclazole FORAN spray karein',
        'Nitrogen fertilizer abhi band karein',
        'Khet mein pani level check karein',
      ],
      'Rice___Neck_Blast': [
        'Isoprothiolane ya Tricyclazole karein',
        'Nitrogen bilkul kam karein',
        'Resistant variety agle season lagayen',
      ],
      'Wheat___Brown_Rust': [
        'Propiconazole ya Tebuconazole spray karein',
        'Jaldi spray zaroori hai tezi se phailti hai',
        'Certified disease-free seed use karein',
      ],
      'Wheat___Yellow_Rust': [
        'Propiconazole immediately spray karein',
        'Neighbors ko bhi inform karein',
        'Resistant wheat variety lagayen',
      ],
    };
    return map[disease] ??
        [
          'Nezdiki Zari Taraqiati Bank se rabta karein',
          'Agricultural helpline: 0800-KISAAN',
        ];
  }
}