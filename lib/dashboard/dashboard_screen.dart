import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/common_widgets/responsive/top_nav_bar.dart';
import 'package:tasks_app/controller/complaint_provider.dart';
import 'package:tasks_app/controller/daily_task_provider.dart';
import 'package:tasks_app/controller/preventive_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/dashboard/widgets/recent_tasks_list.dart';
import 'package:tasks_app/dashboard/widgets/stat_card.dart';
import 'package:tasks_app/dashboard/widgets/task_completion_chart.dart';
import 'package:tasks_app/dashboard/widgets/task_priority_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? selectedDepartment;
  String? selectedAssignee;

  static const _blockedUsernames = {
    'admin',
    'gm',
    'manager',
    'manager1',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['selectedIndex'] != null) {
        setState(() {
          _selectedIndex = args['selectedIndex'] as int;
        });
      }
      _fetchData();
    });
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

    final department = currentUser?.department;
    if (department != null && (role == 'USER')) {
      preventiveProvider.fetchAllPreventiveMaintenanceByDepartment(department);
    } else {
      preventiveProvider.fetchAllPreventiveMaintenanceByDepartment(department ?? '');
    }

    log('Dashboard: Data fetch initiated for role=$role');
  }

  List<String> _buildDepartmentList({
    required String userRole,
    required String userDepartment,
    required List<String> allDepartments,
  }) {
    switch (userRole) {
      case 'USER':
        final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
        selectedDepartment = dept;
        return [dept];
      case 'ADMIN':
      case 'MANAGER':
        final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
        if (selectedDepartment == null) {
          selectedDepartment = dept;
        }
        return [dept];
      case 'GENERAL_MANAGER':
      case 'SECTOR_MANAGER':
        return ['الكل', ...allDepartments];
      default:
        return ['الكل'];
    }
  }

  List<String> _buildAssigneeList({
    required String userRole,
    required String userUsername,
    required String userDepartment,
    required List<Map<String, String>> allUsers,
  }) {
    bool isAllowed(String username) => !_blockedUsernames.contains(username);

    switch (userRole) {
      case 'USER':
        return [userUsername];
      case 'ADMIN':
      case 'MANAGER':
        final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
        final deptUsers = allUsers
            .where((u) => u['department'] == dept)
            .map((u) => u['username']!)
            .where(isAllowed)
            .toSet()
            .toList();
        return ['الكل', ...deptUsers];
      case 'GENERAL_MANAGER':
      case 'SECTOR_MANAGER':
        if (selectedDepartment == null || selectedDepartment == 'الكل') {
          final allUsernames = allUsers
              .map((u) => u['username']!)
              .where(isAllowed)
              .toSet()
              .toList();
          return ['الكل', ...allUsernames];
        } else {
          final deptUsers = allUsers
              .where((u) => u['department'] == selectedDepartment)
              .map((u) => u['username']!)
              .where(isAllowed)
              .toSet()
              .toList();
          return ['الكل', ...deptUsers];
        }
      default:
        return ['الكل'];
    }
  }

  void _clearFilters({
    required String userRole,
    required String userDepartment,
  }) {
    setState(() {
      if (userRole == 'USER' || userRole == 'ADMIN' || userRole == 'MANAGER') {
        selectedDepartment = userDepartment.isEmpty ? 'IT' : userDepartment;
      } else {
        selectedDepartment = 'الكل';
      }
      selectedAssignee = 'الكل';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveScaffold(
      topNavBar: buildRoleTopNavBar(context, _selectedIndex),
      sidebarContent: buildAppSidebar(
        context: context,
        selectedIndex: _selectedIndex,
      ),
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveContentContainer(
        child: Consumer3<DailyTaskProvider, ComplaintProvider, PreventiveProvider>(
          builder: (context, taskProvider, complaintProvider, preventiveProvider, child) {
            if (taskProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            var tasks = taskProvider.tasks;
            final complaints = complaintProvider.complaints;
            final maintenance = preventiveProvider.preventiveMaintenance;

            final userProvider = context.read<UserProvider>();
            final currentUser = userProvider.currentUser;
            final userRole = currentUser?.role ?? '';
            final userUsername = currentUser?.username ?? '';
            final userDepartment = currentUser?.department ?? '';

            final allUsers = userProvider.users
                .map((u) => {
                      'username': u.username,
                      'department': u.department ?? '',
                    })
                .toList();

            final allDepartments = userProvider.users
                .map((u) => u.department ?? '')
                .where((d) => d.isNotEmpty)
                .toSet()
                .toList();

            final departmentList = _buildDepartmentList(
              userRole: userRole,
              userDepartment: userDepartment,
              allDepartments: allDepartments,
            );

            final assigneeList = _buildAssigneeList(
              userRole: userRole,
              userUsername: userUsername,
              userDepartment: userDepartment,
              allUsers: allUsers,
            );

            if (userRole == 'USER') {
              selectedAssignee = userUsername;
            }

            if (!assigneeList.contains(selectedAssignee)) {
              selectedAssignee = assigneeList.first;
            }

            if (!departmentList.contains(selectedDepartment)) {
              selectedDepartment = departmentList.first;
            }

            // Role-based base filter
            if (userRole == 'USER' && userUsername.isNotEmpty) {
              tasks = tasks.where((t) => t.assignedTo == userUsername).toList();
            } else if (userRole == 'ADMIN' || userRole == 'MANAGER') {
              final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
              tasks = tasks.where((t) {
                final taskOwner = allUsers.firstWhere(
                  (u) => u['username'] == t.assignedTo,
                  orElse: () => {'department': ''},
                );
                return taskOwner['department'] == dept;
              }).toList();
            }

            // User-selected filters
            if (selectedAssignee != null && selectedAssignee != 'الكل') {
              tasks = tasks.where((t) => t.assignedTo == selectedAssignee).toList();
            }

            final hasActiveFilters = selectedAssignee != null && selectedAssignee != 'الكل';

            return SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(context),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    context: context,
                    userRole: userRole,
                    userDepartment: userDepartment,
                    userUsername: userUsername,
                    departmentList: departmentList,
                    assigneeList: assigneeList,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    isDesktop: isDesktop,
                    hasActiveFilters: hasActiveFilters,
                  ),
                  const SizedBox(height: 24),
                  _buildStatCards(context, tasks, complaints, maintenance, isDesktop),
                  const SizedBox(height: 24),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: TaskCompletionChart(tasks: tasks)),
                        const SizedBox(width: 16),
                        Expanded(child: TaskPriorityChart(tasks: tasks)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        TaskCompletionChart(tasks: tasks),
                        const SizedBox(height: 16),
                        TaskPriorityChart(tasks: tasks),
                      ],
                    ),
                  const SizedBox(height: 24),
                  RecentTasksList(tasks: tasks),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required BuildContext context,
    required String userRole,
    required String userDepartment,
    required String userUsername,
    required List<String> departmentList,
    required List<String> assigneeList,
    required bool isDark,
    required ColorScheme colorScheme,
    required bool isDesktop,
    required bool hasActiveFilters,
  }) {
    final showDepartmentFilter = userRole != 'USER';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_alt_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'تخصيص',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (hasActiveFilters)
                TextButton.icon(
                  onPressed: () => _clearFilters(
                    userRole: userRole,
                    userDepartment: userDepartment,
                  ),
                  icon: Icon(Icons.clear_rounded, size: 18, color: colorScheme.primary),
                  label: Text(
                    'حذف الفلتر',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (showDepartmentFilter)
                SizedBox(
                  width: isDesktop ? 280 : double.infinity,
                  child: _buildDropdown(
                    label: 'الادارة',
                    value: departmentList.contains(selectedDepartment)
                        ? selectedDepartment!
                        : departmentList.first,
                    items: departmentList,
                    icon: Icons.business_rounded,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    onChanged: (userRole == 'ADMIN' || userRole == 'MANAGER')
                        ? null
                        : (value) {
                            setState(() {
                              selectedDepartment = value;
                              selectedAssignee = 'الكل';
                            });
                          },
                  ),
                ),
              SizedBox(
                width: isDesktop ? 280 : double.infinity,
                child: _buildDropdown(
                  label: 'الموظف',
                  value: assigneeList.contains(selectedAssignee)
                      ? selectedAssignee!
                      : assigneeList.first,
                  items: assigneeList,
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onChanged: userRole == 'USER'
                      ? null
                      : (value) {
                          setState(() => selectedAssignee = value);
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required ColorScheme colorScheme,
    required Function(String?)? onChanged,
  }) {
    final isDisabled = onChanged == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDisabled
                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade50)
                : (isDark ? colorScheme.surface.withValues(alpha: 0.5) : Colors.white),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              onChanged: onChanged,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Cairo',
                color: isDisabled
                    ? Colors.grey.shade400
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.w500,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final displayName = userProvider.currentUser?.displayName ?? 'المستخدم';
    final role = userProvider.currentUser?.role ?? '';
    final roleText = _getRoleText(role);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، $displayName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              size: 40,
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
