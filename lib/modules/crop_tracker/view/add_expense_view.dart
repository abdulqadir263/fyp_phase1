import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../view_model/crop_tracker_view_model.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/date_picker_field.dart';


class AddExpenseView extends StatefulWidget {
  final String cropId;
  const AddExpenseView({super.key, required this.cropId});

  @override
  State<AddExpenseView> createState() =>
      _AddExpenseViewState();
}

class _AddExpenseViewState extends State<AddExpenseView> {
  final vm = Get.find<CropTrackerViewModel>();
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  String _category = 'fertilizer';
  DateTime _date = DateTime.now();

  final _categories = [
    {
      'key': 'fertilizer',
      'label': 'Fertilizer',
      'icon': '🌿',
      'color': Colors.green
    },
    {
      'key': 'pesticide',
      'label': 'Pesticide',
      'icon': '🐛',
      'color': Colors.red
    },
    {
      'key': 'labor',
      'label': 'Labor',
      'icon': '👷',
      'color': Colors.blue
    },
    {
      'key': 'water',
      'label': 'Irrigation',
      'icon': '💧',
      'color': Colors.lightBlue
    },
    {
      'key': 'seed',
      'label': 'Seed',
      'icon': '🌱',
      'color': Colors.teal
    },
    {
      'key': 'machinery',
      'label': 'Machinery',
      'icon': '🚜',
      'color': Colors.brown
    },
    {
      'key': 'other',
      'label': 'Other',
      'icon': '📦',
      'color': Colors.grey
    },
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppConstants.primaryGreen,
        title: const Text(
          'Add Expense',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Category ──
              _label('Expense Category'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected =
                      _category == cat['key'];
                  final color = cat['color'] as Color;
                  return GestureDetector(
                    onTap: () => setState(
                            () => _category = cat['key'] as String),
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.12)
                            : Colors.white,
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        '${cat['icon']} ${cat['label']}',
                        style: TextStyle(
                          color: isSelected
                              ? color
                              : Colors.grey.shade600,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Description ──
              _label('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: _inputDecor(
                  'E.g: DAP 1 bag, Spray 2 litre...',
                  Icons.description_outlined,
                ),
                validator: (v) => v!.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),

              const SizedBox(height: 16),

              // ── Amount ──
              _label('Amount (in Rupees)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: _inputDecor(
                    'E.g: 2500', Icons.money_outlined),
                validator: (v) {
                  if (v!.trim().isEmpty)
                    return 'Amount is required';
                  final n = double.tryParse(v);
                  if (n == null)
                    return 'Enter a valid number';
                  if (n <= 0)
                    return 'Amount must be greater than zero';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Date ──
              _label('Date'),
              const SizedBox(height: 8),
              DatePickerField(
                value: _date,
                icon: Icons.calendar_today,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: ColorScheme.light(
                            primary:
                            AppConstants.primaryGreen),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null)
                    setState(() => _date = d);
                },
              ),

              const SizedBox(height: 32),

              // ── Submit ──
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    AppConstants.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed:
                  vm.isSaving.value ? null : _submit,
                  child: vm.isSaving.value
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2))
                      : const Text(
                    'Save Expense',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              )),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      vm.addExpense(
        widget.cropId,
        category: _category,
        description: _descCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        date: _date,
      );
    }
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Color(0xFF333333)),
  );

  InputDecoration _inputDecor(
      String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon,
            color: AppConstants.primaryGreen, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: AppConstants.primaryGreen,
                width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      );
}