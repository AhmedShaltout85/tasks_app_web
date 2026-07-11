import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tasks_app/controller/complaint_provider.dart';
import 'package:tasks_app/controller/daily_task_provider.dart';
import 'package:tasks_app/controller/preventive_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/dashboard/widgets/recent_tasks_list.dart';
import 'package:tasks_app/dashboard/widgets/stat_card.dart';
import 'package:tasks_app/dashboard/widgets/task_completion_chart.dart';
import 'package:tasks_app/dashboard/widgets/task_priority_chart.dart';
import 'package:tasks_app/models/complaint_model.dart';
import 'package:tasks_app/models/daily_task_model.dart';
import 'package:tasks_app/models/preventive_maintenance_model.dart';

class DashboardContent extends StatefulWidget {
  final String? departmentFilter;
  final String? userFilter;

  const DashboardContent({super.key, this.departmentFilter, this.userFilter});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _hasFetchedData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasFetchedData) {
        _hasFetchedData = true;
        _fetchData();
      }
    });
  }

  @override
  void didUpdateWidget(DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.departmentFilter != widget.departmentFilter) {
      _hasFetchedData = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hasFetchedData = true;
        _fetchData();
      });
    }
  }

  void _fetchData() {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    final role = currentUser?.role;
    final username = currentUser?.username;

    final taskProvider = context.read<DailyTaskProvider>();
    final complaintProvider = context.read<ComplaintProvider>();
    final preventiveProvider = context.read<PreventiveProvider>();

    if (role == 'USER' && username != null) {
      taskProvider.fetchTasksAssignedTo(username);
    } else {
      taskProvider.fetchAllTasks();
    }

    complaintProvider.fetchAllComplaints();

    final department = widget.departmentFilter ?? currentUser?.department ?? '';
    preventiveProvider.fetchAllPreventiveMaintenanceByDepartment(department);

    log('DashboardContent: Data fetch initiated for role=$role, department=$department');
  }

  List<DailyTaskModel> _filterTasksByDepartment(
    List<DailyTaskModel> tasks,
    String department,
  ) {
    final userProvider = context.read<UserProvider>();
    return tasks.where((task) {
      final user = userProvider.users.cast<dynamic>().firstWhere(
            (u) => u.username == task.assignedTo,
            orElse: () => null,
          );
      if (user == null) return false;
      return user.department?.toString() == department;
    }).toList();
  }

  List<ComplaintModel> _filterComplaintsByDepartment(
    List<ComplaintModel> complaints,
    String department,
  ) {
    return complaints.where((c) => c.department == department).toList();
  }

  List<PreventiveMaintenanceModel> _filterMaintenanceByDepartment(
    List<PreventiveMaintenanceModel> maintenance,
    String department,
  ) {
    return maintenance.where((m) => m.department == department).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    final department = widget.departmentFilter;

    return Consumer3<DailyTaskProvider, ComplaintProvider, PreventiveProvider>(
      builder: (context, taskProvider, complaintProvider, preventiveProvider, child) {
        if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        var tasks = taskProvider.tasks;
        var complaints = complaintProvider.complaints;
        var maintenance = preventiveProvider.preventiveMaintenance;

        if (department != null && department.isNotEmpty) {
          tasks = _filterTasksByDepartment(tasks, department);
          complaints = _filterComplaintsByDepartment(complaints, department);
          maintenance = _filterMaintenanceByDepartment(maintenance, department);
        }

        if (widget.userFilter != null && widget.userFilter!.isNotEmpty) {
          tasks = tasks.where((t) => t.assignedTo == widget.userFilter).toList();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: isDesktop ? 16 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context, department),
              const SizedBox(height: 12),
              _buildStatCards(context, tasks, complaints, maintenance, isDesktop),
              const SizedBox(height: 12),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: TaskCompletionChart(tasks: tasks)),
                    const SizedBox(width: 12),
                    Expanded(child: TaskPriorityChart(tasks: tasks)),
                  ],
                )
              else
                Column(
                  children: [
                    TaskCompletionChart(tasks: tasks),
                    const SizedBox(height: 12),
                    TaskPriorityChart(tasks: tasks),
                  ],
                ),
              const SizedBox(height: 12),
              RecentTasksList(tasks: tasks),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String? department) {
    final userProvider = context.watch<UserProvider>();
    final displayName = userProvider.currentUser?.displayName ?? 'المستخدم';
    final role = userProvider.currentUser?.role ?? '';
    final roleText = _getRoleText(role);

    final String subtitle;
    if (department != null && department.isNotEmpty) {
      subtitle = '$roleText — $department';
    } else {
      subtitle = roleText;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مرحباً، $displayName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(
    BuildContext context,
    List tasks,
    List complaints,
    List maintenance,
    bool isDesktop,
  ) {
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => !t.taskStatus).length;
    final pendingTasks = tasks.where((t) => t.taskStatus).length;

    final cards = [
      StatCard(
        title: 'إجمالي المهام',
        value: totalTasks.toString(),
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.task_alt_rounded,
      ),
      StatCard(
        title: 'مكتملة',
        value: completedTasks.toString(),
        color: const Color(0xFF4CAF50),
        icon: Icons.check_circle_outline_rounded,
      ),
      StatCard(
        title: 'معلقة',
        value: pendingTasks.toString(),
        color: const Color(0xFFFF9800),
        icon: Icons.pending_outlined,
      ),
      StatCard(
        title: 'الشكاوى',
        value: complaints.length.toString(),
        color: const Color(0xFFF44336),
        icon: Icons.report_problem_outlined,
      ),
      StatCard(
        title: 'الصيانة الوقائية',
        value: maintenance.length.toString(),
        color: const Color(0xFF2196F3),
        icon: Icons.build_circle_outlined,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: card,
                  ),
                ))
            .toList(),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map((card) => SizedBox(
                width: (MediaQuery.of(context).size.width - 44) / 2,
                child: card,
              ))
          .toList(),
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'ADMIN':
        return 'مدير النظام';
      case 'MANAGER':
        return 'مدير';
      case 'GENERAL_MANAGER':
        return 'مدير عام';
      case 'SECTOR_MANAGER':
        return 'مدير قطاع';
      case 'USER':
        return 'مستخدم';
      default:
        return role;
    }
  }
}
