// widgets/date_picker_field.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? value;
  final String? hint;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const DatePickerField({
    this.value,
    this.hint,
    required this.icon,
    this.iconColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppConstants.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value != null
                  ? '${value!.day}/${value!.month}/${value!.year}'
                  : (hint ?? 'Select date'),
              style: TextStyle(
                color: value != null
                    ? Colors.black87
                    : Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}