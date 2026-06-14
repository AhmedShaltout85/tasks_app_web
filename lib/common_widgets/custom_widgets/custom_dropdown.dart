import 'package:flutter/material.dart';
import 'package:tasks_app/utils/app_colors.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final IconData? icon;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.blackColor87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: Text(hint),
            underline: const SizedBox.shrink(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
