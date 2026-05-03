import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_colors.dart';
import '../models/disease_history_record.dart';
import '../view_model/disease_detection_controller.dart';

/// Displays the user's disease detection history, newest first.
class DiseaseHistoryScreen extends GetView<DiseaseDetectionController> {
  const DiseaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger a single load when the screen first appears.
    // WidgetsBinding ensures it runs after the initial build frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadHistory();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'Detection History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isHistoryLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (controller.historyError.value.isNotEmpty) {
          return _buildErrorState(context);
        }

        if (controller.history.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          color: AppColors.primaryGreen,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _buildHistoryCard(context, controller.history[i]),
          ),
        );
      }),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No History Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved disease detections will appear here.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.eco_rounded),
            label: const Text('Scan a Crop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Failed to load history',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.historyError.value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => controller.loadHistory(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tap to retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── History card ───────────────────────────────────────────────────────────

  Widget _buildHistoryCard(BuildContext context, DiseaseHistoryRecord record) {
    final dateStr =
    DateFormat('MMM dd, yyyy • hh:mm a').format(record.createdAt);
    final severityColor = _severityColor(record.severity);
    final severityLabel = _severityLabel(record.severity);
    final isHealthy = record.severity == 'none';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailSheet(context, record),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isHealthy ? Icons.check_circle_rounded : Icons.bug_report_rounded,
                  color: severityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + severity badge row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.diseaseName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            severityLabel,
                            style: TextStyle(
                              color: severityColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Confidence
                    Text(
                      'Confidence: ${record.confidence.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 6),
                    // Date
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // ── Detail bottom sheet ────────────────────────────────────────────────────

  void _showDetailSheet(BuildContext context, DiseaseHistoryRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, scrollController) => _DetailContent(
          record: record,
          scrollController: scrollController,
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _severityColor(String severity) => switch (severity) {
    'none' => Colors.green.shade600,
    'moderate' => Colors.orange.shade700,
    'high' => Colors.red.shade600,
    'critical' => Colors.red.shade800,
    _ => Colors.grey.shade600,
  };

  String _severityLabel(String severity) => switch (severity) {
    'none' => 'No Risk',
    'moderate' => 'Moderate',
    'high' => 'High Risk',
    'critical' => 'Critical',
    _ => severity,
  };
}

// ── Bottom sheet detail view ───────────────────────────────────────────────

class _DetailContent extends StatefulWidget {
  final DiseaseHistoryRecord record;
  final ScrollController scrollController;

  const _DetailContent({
    required this.record,
    required this.scrollController,
  });

  @override
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  bool _showUrdu = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final isUrdu = _showUrdu;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Toggle + title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: isUrdu
                    ? Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Text(
                    r.diseaseNameUr,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
                    : Text(
                  r.diseaseName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _showUrdu = !_showUrdu),
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  isUrdu ? 'English' : 'اردو',
                  style: const TextStyle(
                      color: AppColors.primaryGreen, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Confidence + date
          Text(
            'Confidence: ${r.confidence.toStringAsFixed(1)}%  •  '
                '${DateFormat('MMM dd, yyyy').format(r.createdAt)}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 16),

          _sectionTitle(
              isUrdu ? 'تفصیل' : 'Description', Icons.info_outline_rounded),
          _sectionBody(isUrdu ? r.descriptionUr : r.description, isUrdu),
          const SizedBox(height: 14),

          _sectionTitle(
              isUrdu ? 'علاج' : 'Treatment', Icons.healing_rounded),
          _sectionBody(isUrdu ? r.treatmentUr : r.treatment, isUrdu),
          const SizedBox(height: 14),

          _sectionTitle(
              isUrdu ? 'احتیاط' : 'Prevention', Icons.shield_rounded),
          _sectionBody(isUrdu ? r.preventionUr : r.prevention, isUrdu),
          const SizedBox(height: 14),

          // Farmer tip
          Container(
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
                        fontSize: 13),
                  ),
                ]),
                const SizedBox(height: 6),
                isUrdu
                    ? Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Text(r.farmerTipUr,
                      style: TextStyle(
                          color: Colors.amber.shade900, height: 1.4)),
                )
                    : Text(r.farmerTip,
                    style: TextStyle(
                        color: Colors.amber.shade900, height: 1.4)),
              ],
            ),
          ),

          // Consult expert for high/critical
          if (r.severity == 'high' || r.severity == 'critical') ...[
            const SizedBox(height: 16),
            SizedBox(
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
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.APPOINTMENTS);
                },
                icon: const Icon(Icons.medical_services_rounded, size: 18),
                label: const Text('Consult Expert',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, color: AppColors.primaryGreen, size: 18),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15)),
    ]),
  );

  Widget _sectionBody(String text, bool isUrdu) => isUrdu
      ? Directionality(
    textDirection: ui.TextDirection.rtl,
    child: Text(text,
        style: TextStyle(
            color: Colors.grey.shade700, height: 1.5, fontSize: 14)),
  )
      : Text(text,
      style: TextStyle(
          color: Colors.grey.shade700, height: 1.5, fontSize: 14));
}