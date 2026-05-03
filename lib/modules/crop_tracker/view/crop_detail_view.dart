import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../view_model/crop_tracker_view_model.dart';
import '../models/crop_model.dart';
import '../widgets/stage_timeline_widget.dart';
import '../widgets/expense_card_widget.dart';
import 'add_expense_view.dart';
import 'harvest_view.dart';
import '../../../core/constants/app_constants.dart';

class CropDetailView extends StatelessWidget {
  final String cropId;
  const CropDetailView({super.key, required this.cropId});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<CropTrackerViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Obx(() {
        final crop =
        vm.crops.firstWhereOrNull((c) => c.id == cropId);
        if (crop == null) {
          return const Center(child: Text('Crop not found'));
        }

        return CustomScrollView(
          slivers: [
            // ── SliverAppBar ──
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: AppConstants.primaryGreen,
              iconTheme:
              const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  crop.cropName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryGreen,
                        AppConstants.primaryGreen
                            .withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white),
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final ok =
                      await _confirmDelete(context);
                      if (ok == true) {
                        vm.deleteCrop(crop.id);
                        Get.back();
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete,
                            color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete',
                            style:
                            TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Info
                  _buildInfoCard(crop),
                  const SizedBox(height: 16),

                  // Stage
                  _sectionTitle('Crop Progress'),
                  const SizedBox(height: 10),
                  StageTimelineWidget(
                    currentStage: crop.currentStage,
                    isHarvested: crop.isHarvested,
                    onStageTap: (stage) =>
                        vm.updateStage(crop.id, stage),
                  ),
                  const SizedBox(height: 20),

                  // Expenses header
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('Expenses'),
                      if (!crop.isHarvested)
                        TextButton.icon(
                          onPressed: () => Get.to(
                                () => AddExpenseView(
                                cropId: crop.id),
                            transition:
                            Transition.downToUp,
                          ),
                          icon: const Icon(Icons.add,
                              size: 16),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                              foregroundColor:
                              AppConstants.primaryGreen),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Expenses list
                  if (crop.expenses.isEmpty)
                    _emptyBox('No expenses yet')
                  else
                    ...crop.expenses.map(
                            (e) => ExpenseCardWidget(expense: e,cropId: crop.id,)),

                  // Total expenses
                  if (crop.expenses.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _totalExpenseBox(crop.totalExpenses),
                  ],

                  const SizedBox(height: 20),

                  // Harvest
                  _sectionTitle('Harvest Details'),
                  const SizedBox(height: 10),
                  if (crop.harvest == null) ...[
                    _emptyBox('No harvest recorded yet'),
                    if (!crop.isHarvested) ...[
                      const SizedBox(height: 10),
                      _harvestButton(crop.id),
                    ],
                  ] else
                    _buildHarvestCard(crop),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoCard(CropRecord crop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: [
        Row(children: [
          Text(_emoji(crop.cropType),
              style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crop.cropName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(_cropLabel(crop.cropType),
                    style: TextStyle(
                        color: AppConstants.primaryGreen,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _statusBadge(crop.isHarvested),
        ]),
        const Divider(height: 20),
        Row(children: [
          _infoTile(Icons.crop_square, 'Area',
              '${crop.areaAcres} Acres'),
          _infoTile(Icons.calendar_today, 'Sowing',
              _fmtDate(crop.sowingDate)),
          _infoTile(
              Icons.timer, 'Days', '${crop.daysInField} days'),
          if (crop.expectedHarvestDate != null)
            _infoTile(Icons.event, 'Harvest',
                _fmtDate(crop.expectedHarvestDate!)),
        ]),
      ]),
    );
  }

  Widget _buildHarvestCard(CropRecord crop) {
    final h = crop.harvest!;
    final isProfit = crop.netProfit >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _harvestStat('🌾', 'Yield', '${h.yieldKg} kg'),
            _harvestStat(
                '💰', 'Price', 'Rs ${h.pricePerKg}/kg'),
            _harvestStat('📦', 'Income',
                'Rs ${h.totalIncome.toStringAsFixed(0)}'),
          ],
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Net ${isProfit ? "Profit" : "Loss"}',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13)),
                  Text(
                    'Rs ${crop.netProfit.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isProfit
                            ? Colors.green.shade700
                            : Colors.red.shade700),
                  ),
                ]),
            Icon(
              isProfit
                  ? Icons.trending_up
                  : Icons.trending_down,
              color: isProfit ? Colors.green : Colors.red,
              size: 40,
            ),
          ],
        ),
        if (h.notes.isNotEmpty) ...[
          const Divider(height: 16),
          Row(children: [
            Icon(Icons.note,
                size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Expanded(
                child: Text(h.notes,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13))),
          ]),
        ],
      ]),
    );
  }

  Widget _harvestButton(String cropId) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: () => Get.to(
            () => HarvestView(cropId: cropId),
        transition: Transition.downToUp,
      ),
      icon: const Icon(Icons.agriculture),
      label: const Text('Record Harvest',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _totalExpenseBox(double total) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Total Expenses:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Rs ${total.toStringAsFixed(0)}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
                fontSize: 16)),
      ],
    ),
  );

  Widget _statusBadge(bool isHarvested) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: isHarvested
          ? Colors.green.shade100
          : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      isHarvested ? '✅ Harvested' : '🌱 Active',
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isHarvested
              ? Colors.green.shade700
              : Colors.blue.shade700),
    ),
  );

  Widget _infoTile(
      IconData icon, String label, String value) =>
      Expanded(
        child: Column(children: [
          Icon(icon,
              size: 18, color: AppConstants.primaryGreen),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center),
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _harvestStat(
      String emoji, String label, String value) =>
      Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 11)),
      ]);

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color(0xFF333333)));

  Widget _emptyBox(String msg) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
          child: Text(msg,
              style:
              TextStyle(color: Colors.grey.shade400))));

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
  String _emoji(String t) {
    switch (t) {
      case 'rice': return '🌾';
      case 'corn': return '🌽';
      case 'wheat': return '🌿';
      case 'potato': return '🥔';
      case 'sugarcane': return '🎋';
      case 'cotton': return '☁️';
      default: return '🌱';
    }
  }

  String _cropLabel(String t) {
    switch (t) {
      case 'rice': return 'Rice';
      case 'corn': return 'Corn';
      case 'wheat': return 'Wheat';
      case 'potato': return 'Potato';
      case 'sugarcane': return 'Sugarcane';
      case 'cotton': return 'Cotton';
      default: return 'Crop';
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete?'),
          content: const Text(
              'This record will be permanently deleted.'),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('No')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: () => Get.back(result: true),
              child: const Text('Yes, Delete',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}