import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../service/disease_detector.dart';
import '../service/disease_service.dart';
import '../view_model/disease_detection_controller.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen>
    with SingleTickerProviderStateMixin {
  final DiseaseService _service = DiseaseService();
  final ImagePicker _picker = ImagePicker();

  // Controller for save-to-history / history navigation
  late final DiseaseDetectionController _ctrl;

  File? _pickedFile;
  DiseaseResult? _result;
  bool _loading = false;
  bool _modelReady = false;
  String _loadingMsg = 'Loading AI model...';

  // Language toggle — false = English, true = Urdu
  bool _showUrdu = false;

  // Animation controller for critical severity pulse
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<DiseaseDetectionController>();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);
    _initModel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _service.dispose();
    super.dispose();
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

      final file = File(picked.path);
      setState(() {
        _pickedFile = file;
        _loading = true;
        _result = null;
        _showUrdu = false;
        _loadingMsg = 'AI is analyzing...';
      });

      final result = await _service.detect(file);

      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
          _loadingMsg = '';
        });
        // Sync to controller so the save button can persist this result
        _ctrl.currentResult.value = result;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMsg = '';
        });
        Get.snackbar(
          'Error',
          'Could not get image: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  // ── Severity helpers ───────────────────────────────────────────────────────

  Color _severityColor(String severity) {
    switch (severity) {
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

  String _severityLabel(String severity) {
    switch (severity) {
      case 'none':
        return 'No Risk';
      case 'moderate':
        return 'Moderate';
      case 'high':
        return 'High Risk';
      case 'critical':
        return 'Critical';
      default:
        return severity;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'none':
        return Icons.check_circle_rounded;
      case 'moderate':
        return Icons.warning_amber_rounded;
      case 'high':
        return Icons.dangerous_rounded;
      case 'critical':
        return Icons.emergency_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppConstants.primaryGreen,
        title: const Text(
          'Disease Detection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Detection History',
            onPressed: () => Get.toNamed(AppRoutes.DISEASE_DETECTION_HISTORY),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_modelReady) _buildStatusBar(),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildImagePreview(),
            const SizedBox(height: 16),
            _buildMobileButtons(),
            const SizedBox(height: 20),
            if (_loading) _buildLoadingWidget(),
            if (_result != null && !_loading) _buildResultCard(_result!),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Status bar ───────────────────────
  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.orange.shade700),
        ),
        const SizedBox(width: 10),
        Text(
          _loadingMsg,
          style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
        ),
      ]),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────

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
            'Take a photo of a leaf — supports Rice, Corn, Wheat, and Potato.',
            style: TextStyle(
                color: AppConstants.primaryGreen, fontSize: 13, height: 1.4),
          ),
        ),
      ]),
    );
  }

  // ── Image preview ──────────────────────────────────────────────────────────

  Widget _buildImagePreview() {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _pickedFile == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco_outlined,
                    size: 70,
                    color:
                        AppConstants.primaryGreen.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text(
                  'Captured photo will appear here',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _pickedFile!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _pickedFile = null;
                      _result = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Mobile buttons ─────────────────────────────────────────────────────────

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
          onPressed:
              _modelReady ? () => _pickImage(ImageSource.camera) : null,
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
          onPressed:
              _modelReady ? () => _pickImage(ImageSource.gallery) : null,
          icon: const Icon(Icons.photo_library, size: 20),
          label: const Text('Gallery',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  // ── Loading widget ─────────────────────────────────────────────────────────

  Widget _buildLoadingWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          CircularProgressIndicator(color: AppConstants.primaryGreen),
          const SizedBox(height: 10),
          Text(
            _loadingMsg,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── Result card ────────────────────────────────────────────────────────────

  Widget _buildResultCard(DiseaseResult result) {
    final isUrdu = _showUrdu;
    final isHealthy = result.severity == 'none';
    final isHighRisk =
        result.severity == 'high' || result.severity == 'critical';
    final isCritical = result.severity == 'critical';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHealthy ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Language toggle ─────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showUrdu = !_showUrdu),
                  icon: Icon(
                    Icons.translate_rounded,
                    size: 16,
                    color: AppConstants.primaryGreen,
                  ),
                  label: Text(
                    isUrdu
                        ? 'View in English'
                        : 'اردو میں دیکھیں',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppConstants.primaryGreen,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppConstants.primaryGreen),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),

          // ── Header: disease name ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
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
                    child: isUrdu
                        ? Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              result.diseaseNameUr,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isHealthy
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          )
                        : Text(
                            result.diseaseName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isHealthy
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                  ),
                ]),
                const SizedBox(height: 10),

                // ── Severity badge ──────────────────────────────────────
                _buildSeverityBadge(result.severity, result.severityUr,
                    isCritical, isUrdu),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Confidence bar ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Confidence',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                    Text(
                      '${result.confidence.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isHealthy ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: result.confidence / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: isHealthy ? Colors.green : Colors.red,
                    minHeight: 8,
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // ── Description ───────────────────────────────────────
                _buildSection(
                  icon: Icons.info_outline_rounded,
                  title: 'Description',
                  titleUr: 'تفصیل',
                  body: result.description,
                  bodyUr: result.descriptionUr,
                  isUrdu: isUrdu,
                ),
                const SizedBox(height: 14),

                // ── Treatment ─────────────────────────────────────────
                _buildSection(
                  icon: Icons.healing_rounded,
                  title: 'Treatment',
                  titleUr: 'علاج',
                  body: result.treatment,
                  bodyUr: result.treatmentUr,
                  isUrdu: isUrdu,
                ),
                const SizedBox(height: 14),

                // ── Prevention ────────────────────────────────────────
                _buildSection(
                  icon: Icons.shield_rounded,
                  title: 'Prevention',
                  titleUr: 'احتیاط',
                  body: result.prevention,
                  bodyUr: result.preventionUr,
                  isUrdu: isUrdu,
                ),
                const SizedBox(height: 14),

                // ── Farmer tip ────────────────────────────────────────
                _buildTipBox(
                  tip: result.farmerTip,
                  tipUr: result.farmerTipUr,
                  isUrdu: isUrdu,
                ),

                const SizedBox(height: 16),

                // ── Save to history ───────────────────────────────────
                _buildSaveButton(),

                const SizedBox(height: 10),

                // ── Consult Expert (only for high / critical) ─────────
                if (isHighRisk) _buildConsultExpertButton(),

                const SizedBox(height: 8),

                // ── Retry ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _pickedFile = null;
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

  // ── Severity badge ─────────────────────────────────────────────────────────

  Widget _buildSeverityBadge(
    String severity,
    String severityUr,
    bool isCritical,
    bool isUrdu,
  ) {
    final color = _severityColor(severity);
    final label = isUrdu ? severityUr : _severityLabel(severity);
    final icon = _severityIcon(severity);

    final badge = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulse =
            isCritical ? _pulseAnimation.value * 0.4 : 0.0;
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12 + pulse),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(
                  alpha: isCritical ? 0.6 + pulse * 0.4 : 0.5),
              width: isCritical ? 2.0 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              isUrdu
                  ? Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ],
          ),
        );
      },
    );

    return badge;
  }

  // ── Section helper ─────────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String titleUr,
    required String body,
    required String bodyUr,
    required bool isUrdu,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: AppConstants.primaryGreen, size: 18),
          const SizedBox(width: 6),
          isUrdu
              ? Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    titleUr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      fontSize: 15,
                    ),
                  ),
                )
              : Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    fontSize: 15,
                  ),
                ),
        ]),
        const SizedBox(height: 6),
        isUrdu
            ? Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  bodyUr,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              )
            : Text(
                body,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
      ],
    );
  }

  // ── Farmer tip box ─────────────────────────────────────────────────────────

  Widget _buildTipBox({
    required String tip,
    required String tipUr,
    required bool isUrdu,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_rounded,
                color: Colors.amber.shade700, size: 16),
            const SizedBox(width: 6),
            Text(
              isUrdu ? 'کسان ٹپ' : 'Farmer Tip',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
                fontSize: 13,
              ),
            ),
          ]),
          const SizedBox(height: 6),
          isUrdu
              ? Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    tipUr,
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                )
              : Text(
                  tip,
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
        ],
      ),
    );
  }

  // ── Save result button ─────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Obx(() {
      final isSaving = _ctrl.isSaving.value;
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryGreen,
            side: BorderSide(
              color: isSaving ? Colors.grey.shade300 : AppConstants.primaryGreen,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: isSaving ? null : _ctrl.saveCurrentResult,
          icon: isSaving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppConstants.primaryGreen),
                )
              : const Icon(Icons.save_rounded, size: 20),
          label: Text(
            isSaving ? 'Saving…' : 'Save Result',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      );
    });
  }

  // ── Consult Expert button ──────────────────────────────────────────────────

  Widget _buildConsultExpertButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: () => Get.toNamed(AppRoutes.APPOINTMENTS),
        icon: const Icon(Icons.medical_services_rounded, size: 18),
        label: const Text(
          'Consult Expert',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}