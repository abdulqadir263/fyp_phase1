import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../view_model/crop_tracker_view_model.dart';
import 'package:get/get.dart';

class ExpenseCardWidget extends StatelessWidget {
  final CropExpense expense;
  final String cropId;

  const ExpenseCardWidget({
    super.key,
    required this.expense,
    required this.cropId,
  });

  IconData get _icon {
    switch (expense.category) {
      case 'fertilizer': return Icons.grass;
      case 'pesticide': return Icons.bug_report;
      case 'labor': return Icons.people;
      case 'water': return Icons.water_drop;
      case 'seed': return Icons.eco;
      case 'machinery': return Icons.agriculture;
      default: return Icons.receipt_outlined;
    }
  }

  Color get _color {
    switch (expense.category) {
      case 'fertilizer': return Colors.green;
      case 'pesticide': return Colors.red;
      case 'labor': return Colors.blue;
      case 'water': return Colors.lightBlue;
      case 'seed': return Colors.teal;
      case 'machinery': return Colors.brown;
      default: return Colors.grey;
    }
  }

  String get _categoryLabel {
    switch (expense.category) {
      case 'fertilizer': return 'Fertilizer';
      case 'pesticide': return 'Pesticide';
      case 'labor': return 'Mazdoori';
      case 'water': return 'Aabpashi';
      case 'seed': return 'Beej';
      case 'machinery': return 'Machinery';
      default: return 'Doosra';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // ── Swipe to delete ──
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        final vm = Get.find<CropTrackerViewModel>();
        vm.deleteExpense(cropId, expense.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 26),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          // ── Category Icon ──
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),

          // ── Description + Category ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _categoryLabel,
                      style: TextStyle(
                          fontSize: 10,
                          color: _color,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11),
                  ),
                ]),
              ],
            ),
          ),

          // ── Amount ──
          Text(
            'Rs ${expense.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
              fontSize: 15,
            ),
          ),

          const SizedBox(width: 8),

          // ── Edit + Delete icons ──
          Column(children: [
            // Edit
            GestureDetector(
              onTap: () => _showEditDialog(context),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.edit_outlined,
                    size: 16, color: Colors.blue.shade600),
              ),
            ),
            const SizedBox(height: 4),
            // Delete
            GestureDetector(
              onTap: () async {
                final ok = await _confirmDelete(context);
                if (ok == true) {
                  final vm = Get.find<CropTrackerViewModel>();
                  vm.deleteExpense(cropId, expense.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.delete_outline,
                    size: 16, color: Colors.red.shade400),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Edit Dialog ──
  void _showEditDialog(BuildContext context) {
    final amountCtrl = TextEditingController(
        text: expense.amount.toStringAsFixed(0));
    final descCtrl =
    TextEditingController(text: expense.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Kharcha Edit Karo',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Tafseelaat',
                prefixIcon: Icon(Icons.description_outlined,
                    color: Colors.green.shade600),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.green.shade600,
                      width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Raqam (Rs)',
                prefixIcon: const Icon(
                    Icons.currency_rupee,
                    color: Colors.red),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Colors.red, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  final newAmount =
                  double.tryParse(amountCtrl.text);
                  if (newAmount == null || newAmount <= 0)
                    return;
                  if (descCtrl.text.trim().isEmpty) return;

                  final vm =
                  Get.find<CropTrackerViewModel>();
                  vm.editExpense(
                    cropId,
                    expenseId: expense.id,
                    newDescription: descCtrl.text.trim(),
                    newAmount: newAmount,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save Karo',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hata Dein?'),
          content: Text(
              '"${expense.description}" ka kharcha hata dein?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nahi'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Haan Hata Do',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}