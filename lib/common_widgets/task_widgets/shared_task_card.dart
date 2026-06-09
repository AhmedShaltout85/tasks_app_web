import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color getCardColor(dynamic task) {
  final colorMap = {
    'HIGH': Colors.red.shade50,
    'MEDIUM': Colors.orange.shade50,
    'LOW': Colors.blue.shade50,
  };

  return colorMap[task.taskPriority?.toUpperCase()] ?? Colors.grey.shade50;
}

Color getBorderColor(dynamic task) {
  final colorMap = {
    'HIGH': Colors.red.shade300,
    'MEDIUM': Colors.orange.shade300,
    'LOW': Colors.blue.shade300,
  };

  return colorMap[task.taskPriority?.toUpperCase()] ?? Colors.grey.shade300;
}

class SharedPriorityBadge extends StatelessWidget {
  final String priority;

  const SharedPriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (priority.toUpperCase()) {
      case 'HIGH':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.priority_high;
        break;
      case 'MEDIUM':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.remove;
        break;
      case 'LOW':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.low_priority;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class SharedDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const SharedDetailRow({
    super.key,
    required this.icon,
    this.label = '',
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: onSurface),
              children: [
                if (label.isNotEmpty)
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                    ),
                  ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w500,
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SharedTaskCard extends StatelessWidget {
  final dynamic task;
  final bool isOverdue;
  final List<Widget> actions;

  const SharedTaskCard({
    super.key,
    required this.task,
    this.isOverdue = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: getBorderColor(task), width: 2.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getCardColor(task),
                getCardColor(task).withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.taskTitle ?? '',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (isOverdue)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'متاخرة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    SharedPriorityBadge(
                      priority: task.taskPriority ?? 'MEDIUM',
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                SharedDetailRow(
                  icon: Icons.business,
                  value: task.appName ?? '',
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                SharedDetailRow(
                  icon: Icons.person_outline,
                  value: task.assignedBy ?? '',
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 8),
                SharedDetailRow(
                  icon: Icons.person,
                  value: task.assignedTo ?? '',
                  color: Colors.teal,
                ),
                const SizedBox(height: 8),
                SharedDetailRow(
                  icon: Icons.location_on,
                  value: task.visitPlace ?? '',
                  color: Colors.red,
                ),
                if (task.subPlace != null && task.subPlace.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SharedDetailRow(
                    icon: Icons.location_on_outlined,
                    value: task.subPlace ?? '',
                    color: Colors.orange,
                  ),
                ],
                const SizedBox(height: 8),
                SharedDetailRow(
                  icon: Icons.calendar_month,
                  value: task.expectedCompletionDate != null
                      ? DateFormat('yyyy-MM-dd')
                          .format(task.expectedCompletionDate)
                      : '',
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                SharedDetailRow(
                  icon: Icons.group,
                  value: task.coOperator != null && task.coOperator.isNotEmpty
                      ? task.coOperator.join(', ')
                      : 'لا يوجد شركاء',
                  color: Colors.brown,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildStatusBadge(context),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ...actions,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: task.taskStatus == true
            ? Colors.green.shade100
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: task.taskStatus == true
              ? Colors.green.shade400
              : Colors.grey.shade400,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            task.taskStatus == true ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: task.taskStatus == true
                ? Colors.green.shade700
                : Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            task.taskStatus == true ? 'نشط' : 'غير نشط',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: task.taskStatus == true
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
