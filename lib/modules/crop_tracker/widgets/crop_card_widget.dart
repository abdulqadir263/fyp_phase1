import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../../../core/constants/app_constants.dart';

class CropCardWidget extends StatelessWidget {
  final CropRecord crop;
  final VoidCallback onTap;

  const CropCardWidget({
    super.key,
    required this.crop,
    required this.onTap,
  });

  String get _emoji {
    switch (crop.cropType) {
      case 'rice': return '🌾';
      case 'corn': return '🌽';
      case 'wheat': return '🌿';
      case 'potato': return '🥔';
      case 'sugarcane': return '🎋';
      case 'cotton': return '☁️';
      default: return '🌱';
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = crop.expectedHarvestDate != null
        ? crop.expectedHarvestDate!
        .difference(DateTime.now())
        .inDays
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: crop.isHarvested
                ? Colors.green.shade200
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            // ── Top Row ──
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(_emoji,
                      style:
                      const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.cropName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${crop.areaAcres} Acres  •  ${crop.daysInField} din se khet mein',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusBadge(crop.isHarvested),
                  if (daysLeft != null && !crop.isHarvested)
                    ...[
                      const SizedBox(height: 4),
                      Text(
                        daysLeft > 0
                            ? '$daysLeft din baqi'
                            : 'Katai ka waqt!',
                        style: TextStyle(
                          fontSize: 11,
                          color: daysLeft > 0
                              ? Colors.orange.shade600
                              : Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                ],
              ),
            ]),

            const SizedBox(height: 12),

            // ── Stage Progress Bar ──
            _StageBar(stage: crop.currentStage),

            const SizedBox(height: 12),

            // ── Bottom Stats ──
            Row(children: [
              _MiniStat(
                icon: Icons.money_off,
                label: 'Kharcha',
                value:
                'Rs ${_fmt(crop.totalExpenses)}',
                color: Colors.red.shade400,
              ),
              const SizedBox(width: 8),
              if (crop.harvest != null)
                _MiniStat(
                  icon: Icons.attach_money,
                  label: 'Amdani',
                  value: 'Rs ${_fmt(crop.harvest!.totalIncome)}',
                  color: Colors.green.shade500,
                ),
              if (crop.harvest != null)
                const SizedBox(width: 8),
              _MiniStat(
                icon: crop.netProfit >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                label: crop.netProfit >= 0
                    ? 'Munafa'
                    : 'Nuqsan',
                value:
                'Rs ${_fmt(crop.netProfit.abs())}',
                color: crop.netProfit >= 0
                    ? Colors.green.shade600
                    : Colors.red.shade600,
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statusBadge(bool isHarvested) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: isHarvested
          ? Colors.green.shade100
          : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      isHarvested ? '✅ Kati' : '🌱 Active',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isHarvested
            ? Colors.green.shade700
            : Colors.blue.shade700,
      ),
    ),
  );

  String _fmt(double n) {
    if (n >= 1000)
      return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

class _StageBar extends StatelessWidget {
  final CropStage stage;
  const _StageBar({required this.stage});

  @override
  Widget build(BuildContext context) {
    final stages = CropStage.values;
    return Row(
      children: stages.asMap().entries.map((e) {
        final isDone = e.key <= stage.index;
        final isCurrent = e.key == stage.index;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
                right: e.key < stages.length - 1 ? 3 : 0),
            child: Column(children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppConstants.primaryGreen
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    stages[e.key].emoji,
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500)),
                Text(value,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
