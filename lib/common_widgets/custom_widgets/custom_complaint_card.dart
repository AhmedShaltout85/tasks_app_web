import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'custom_text.dart';

class CustomComplaintCard extends StatelessWidget {
  final dynamic complaint;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onCreateTask;

  const CustomComplaintCard({
    super.key,
    required this.complaint,
    this.onDelete,
    this.onEdit,
    this.onCreateTask,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone_android, complaint.appName),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.report_problem, complaint.complaintName),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.location_on,
                '${complaint.placeName}${complaint.subPlace != 'none' ? ' - ${complaint.subPlace}' : ''}'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.business, complaint.department),
            const SizedBox(height: 6),
            _buildInfoRow(
                Icons.person, '${complaint.empName} (${complaint.empNumber})'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.phone, complaint.empMobile),
            if (onDelete != null || onEdit != null || onCreateTask != null) ...[
              const Divider(height: 16),
              _buildActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: complaint.isEnable
                ? AppColors.successColor.withOpacity(0.1)
                : AppColors.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: complaint.isEnable
                  ? AppColors.successColor
                  : AppColors.errorColor,
            ),
          ),
          child: CustomText(
            text: complaint.isEnable ? 'مفعل' : 'معطل',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: complaint.isEnable
                ? AppColors.successColor
                : AppColors.errorColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: CustomText(
            text: complaint.appName,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grayColor),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            text: text,
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: AppColors.grayColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onCreateTask != null)
          IconButton(
            onPressed: onCreateTask,
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.successColor),
            tooltip: 'إنشاء مهمة',
          ),
        if (onCreateTask != null) const Spacer(),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon:
                const Icon(Icons.edit_outlined, color: AppColors.infoColor),
            tooltip: 'تعديل',
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon:
                const Icon(Icons.delete_outline, color: AppColors.errorColor),
            tooltip: 'حذف',
          ),
      ],
    );
  }
}
