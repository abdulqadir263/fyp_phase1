import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../view_model/crop_tracker_view_model.dart';
import '../widgets/date_picker_field.dart';

class HarvestView extends StatefulWidget {
  final String cropId;
  const HarvestView({super.key, required this.cropId});

  @override
  State<HarvestView> createState() => _HarvestViewState();
}

class _HarvestViewState extends State<HarvestView> {
  final vm = Get.find<CropTrackerViewModel>();
  final _formKey = GlobalKey<FormState>();
  final _yieldCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _harvestDate = DateTime.now();

  double get _preview {
    final y = double.tryParse(_yieldCtrl.text) ?? 0;
    final p = double.tryParse(_priceCtrl.text) ?? 0;
    return y * p;
  }

  @override
  void dispose() {
    _yieldCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.amber.shade700,
        title: const Text(
          'Katai Record Karo',
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
              // ── Header ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.amber.shade200),
                ),
                child: Row(children: [
                  const Text('🌾',
                      style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mubarak ho! 🎉',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                              Colors.amber.shade800),
                        ),
                        Text(
                          'Katai ki tafseelaat darj karein',
                          style: TextStyle(
                              color: Colors.amber.shade700,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Yield ──
              _label('Paidawar (KG mein)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _yieldCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(
                    decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: _inputDecor(
                  'Jaise: 1500',
                  Icons.scale,
                  Colors.amber.shade700,
                ),
                validator: (v) {
                  if (v!.trim().isEmpty)
                    return 'Paidawar zaroori hai';
                  if (double.tryParse(v) == null)
                    return 'Sahi number likhein';
                  if (double.parse(v) <= 0)
                    return 'Zero se zyada hona chahiye';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Price ──
              _label('Bhaao (Rs per KG)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(
                    decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: _inputDecor(
                  'Jaise: 80',
                  Icons.currency_rupee,
                  Colors.amber.shade700,
                ),
                validator: (v) {
                  if (v!.trim().isEmpty)
                    return 'Bhaao zaroori hai';
                  if (double.tryParse(v) == null)
                    return 'Sahi number likhein';
                  if (double.parse(v) <= 0)
                    return 'Zero se zyada hona chahiye';
                  return null;
                },
              ),

              // ── Live Preview ──
              if (_preview > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Text('💰',
                            style:
                            TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Kul Amdani:',
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500),
                        ),
                      ]),
                      Text(
                        'Rs ${_preview.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Harvest Date ──
              _label('Katai ki Tarikh'),
              const SizedBox(height: 8),
              DatePickerField(
                value: _harvestDate,
                icon: Icons.calendar_today,
                iconColor: Colors.amber.shade700,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _harvestDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 30)),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: ColorScheme.light(
                            primary:
                            Colors.amber.shade700),
                      ),
                      child: child!,
                    ),
                  );
                  if (d != null)
                    setState(() => _harvestDate = d);
                },
              ),

              const SizedBox(height: 16),

              // ── Notes ──
              _label('Notez (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: _inputDecor(
                  'Jaise: Acha fasal hua, barish ki wajah se naqsan...',
                  Icons.note_outlined,
                  Colors.amber.shade700,
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit ──
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
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
                    '🌾 Katai Save Karo',
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
      vm.recordHarvest(
        widget.cropId,
        yieldKg: double.parse(_yieldCtrl.text.trim()),
        pricePerKg: double.parse(_priceCtrl.text.trim()),
        harvestDate: _harvestDate,
        notes: _notesCtrl.text.trim(),
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
      String hint,
      IconData icon,
      Color color,
      ) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: color, size: 20),
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
            borderSide:
            BorderSide(color: color, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      );
}