import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../../../core/constants/app_constants.dart';

class StageTimelineWidget extends StatelessWidget {
  final CropStage currentStage;
  final bool isHarvested;
  final Function(CropStage)? onStageTap;

  const StageTimelineWidget({
    super.key,
    required this.currentStage,
    required this.isHarvested,
    this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    final stages = CropStage.values;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: stages.asMap().entries.map((entry) {
          final idx = entry.key;
          final stage = entry.value;
          final isDone = idx < currentStage.index;
          final isCurrent = idx == currentStage.index;
          final isLast = idx == stages.length - 1;
          final canTap = !isHarvested &&
              !isDone &&
              !isCurrent &&
              onStageTap != null;

          return Row(children: [
            // ── Left: circle + connector ──
            Column(children: [
              GestureDetector(
                onTap: canTap
                    ? () => _confirm(context, stage)
                    : null,
                child: AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppConstants.primaryGreen
                        : isCurrent
                        ? AppConstants.primaryGreen
                        .withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: isDone || isCurrent
                          ? AppConstants.primaryGreen
                          : Colors.grey.shade300,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check,
                        color: Colors.white,
                        size: 18)
                        : Text(stage.emoji,
                        style: const TextStyle(
                            fontSize: 16)),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: isDone
                      ? AppConstants.primaryGreen
                      : Colors.grey.shade200,
                ),
            ]),

            const SizedBox(width: 14),

            // ── Right: text ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 28),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.nameEn,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isDone
                                ? Colors.black87
                                : isCurrent
                                ? AppConstants
                                .primaryGreen
                                : Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          stage.nameUr,
                          style: TextStyle(
                              fontSize: 11,
                              color:
                              Colors.grey.shade400),
                        ),
                      ],
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryGreen
                              .withValues(alpha: 0.1),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Abhi',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppConstants.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (canTap)
                      Icon(Icons.touch_app,
                          size: 16,
                          color: Colors.grey.shade300),
                  ],
                ),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  void _confirm(BuildContext context, CropStage stage) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Stage Update Karein?'),
        content: Text(
          '${stage.emoji} ${stage.nameEn} (${stage.nameUr})\nmein move karein?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nahi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor:
                AppConstants.primaryGreen),
            onPressed: () {
              Navigator.pop(context);
              onStageTap!(stage);
            },
            child: const Text('Haan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
