
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../view_model/crop_tracker_view_model.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/date_picker_field.dart';

class AddCropView extends StatefulWidget {
  const AddCropView({super.key});

  @override
  State<AddCropView> createState() => _AddCropViewState();
}

class _AddCropViewState extends State<AddCropView> {
  final vm = Get.find<CropTrackerViewModel>();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  String _selectedType = 'rice';
  DateTime _sowingDate = DateTime.now();
  DateTime? _harvestDate;

  final _cropTypes = [
    {'key': 'rice',      'label': 'Chawal (Rice)',   'icon': '🌾'},
    {'key': 'corn',      'label': 'Makka (Corn)',    'icon': '🌽'},
    {'key': 'wheat',     'label': 'Gehun (Wheat)',   'icon': '🌿'},
    {'key': 'potato',    'label': 'Aloo (Potato)',   'icon': '🥔'},
    {'key': 'sugarcane', 'label': 'Ganna',           'icon': '🎋'},
    {'key': 'cotton',    'label': 'Kapas',           'icon': '☁️'},
    {'key': 'other',     'label': 'Doosri Fasal',    'icon': '🌱'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppConstants.primaryGreen,
        title: const Text(
          'Nai Fasal Add Karo',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
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
              // ── Crop Type ──
              _sectionLabel('Fasal ki Qisam'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cropTypes.map((type) {
                  final isSelected =
                      _selectedType == type['key'];
                  return GestureDetector(
                    onTap: () => setState(
                            () => _selectedType = type['key']!),
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppConstants.primaryGreen
                            : Colors.white,
                        borderRadius:
                        BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected
                              ? AppConstants.primaryGreen
                              : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: AppConstants
                                .primaryGreen
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                            : null,
                      ),
                      child: Text(
                        '${type['icon']} ${type['label']}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
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

              // ── Crop Name ──
              _sectionLabel('Fasal ka Naam'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization:
                TextCapitalization.words,
                decoration: _inputDecor(
                  'Jaise: Basmati 385, Hybrid Corn...',
                  Icons.eco_outlined,
                ),
                validator: (v) =>
                v!.trim().isEmpty ? 'Naam zaroori hai' : null,
              ),

              const SizedBox(height: 16),

              // ── Area ──
              _sectionLabel('Rukba (Acres mein)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _areaCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: _inputDecor(
                    'Jaise: 2.5', Icons.crop_square),
                validator: (v) {
                  if (v!.trim().isEmpty)
                    return 'Rukba zaroori hai';
                  if (double.tryParse(v) == null)
                    return 'Sahi number likhein';
                  if (double.parse(v) <= 0)
                    return 'Rukba zero se zyada hona chahiye';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Sowing Date ──
              _sectionLabel('Bai ki Tarikh'),
              const SizedBox(height: 8),
              DatePickerField(
                value: _sowingDate,
                icon: Icons.calendar_today,
                onTap: () async {
                  final d = await _pickDate(
                    initial: _sowingDate,
                    first: DateTime(2020),
                    last: DateTime.now(),
                  );
                  if (d != null)
                    setState(() => _sowingDate = d);
                },
              ),

              const SizedBox(height: 16),

              // ── Expected Harvest ──
              _sectionLabel('Mutawaqqa Katai (Optional)'),
              const SizedBox(height: 8),
              DatePickerField(
                value: _harvestDate,
                hint: 'Tarikh select karein',
                icon: Icons.event,
                onTap: () async {
                  final d = await _pickDate(
                    initial: _harvestDate ??
                        _sowingDate
                            .add(const Duration(days: 90)),
                    first: _sowingDate
                        .add(const Duration(days: 1)),
                    last: DateTime(2030),
                  );
                  if (d != null)
                    setState(() => _harvestDate = d);
                },
                trailing: _harvestDate != null
                    ? GestureDetector(
                  onTap: () => setState(
                          () => _harvestDate = null),
                  child: Icon(Icons.close,
                      size: 18,
                      color: Colors.grey.shade400),
                )
                    : null,
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
                    'Fasal Add Karo',
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
      vm.addCrop(
        cropName: _nameCtrl.text.trim(),
        cropType: _selectedType,
        areaAcres: double.parse(_areaCtrl.text.trim()),
        sowingDate: _sowingDate,
        expectedHarvestDate: _harvestDate,
      );
    }
  }

  Future<DateTime?> _pickDate({
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) =>
      showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
                primary: AppConstants.primaryGreen),
          ),
          child: child!,
        ),
      );

  Widget _sectionLabel(String t) => Text(
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
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      );
}