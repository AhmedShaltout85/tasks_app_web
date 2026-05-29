import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/controller/about_app_provider.dart';
import 'package:tasks_app/controller/daily_task_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/controller/place_name_provider.dart';
import 'package:tasks_app/models/daily_task_model.dart';
import 'package:tasks_app/screens/report/widgets/generate_pdf.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  DateTime? startDate;
  DateTime? endDate;
  String? selectedAssignee;
  String? selectedApplication;
  String? selectedVisitPlace;
  String? selectedStatus;
  String? selectedIsRemote;
  String? selectedDepartment;
  bool _isFilterExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> statusList = ['الكل', 'معلق', 'مكتمل'];
  final List<String> isRemoteList = ['الكل', 'عن بعد', 'فى الموقع'];

  @override
  void initState() {
    super.initState();
    selectedAssignee = 'الكل';
    selectedApplication = 'الكل';
    selectedVisitPlace = 'الكل';
    selectedStatus = 'الكل';
    selectedIsRemote = 'الكل';
    selectedDepartment = 'الكل';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  /// Blocked usernames that are system/admin accounts — never shown in assignee list
  static const _blockedUsernames = {
    'admin',
    'gm',
    'manager',
    'manager1',
  };

  /// Returns the department list and sets [selectedDepartment] based on role.
  /// Called once per build so the returned list is always consistent.
  List<String> _buildDepartmentList({
    required String userRole,
    required String userDepartment,
    required List<String> allDepartments,
  }) {
    switch (userRole) {
      case 'USER':
        // USER sees only their own department — lock it
        final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
        // Force selectedDepartment to their dept; they cannot change it
        selectedDepartment = dept;
        return [dept];

      case 'ADMIN':
      case 'MANAGER':
        // ADMIN / MANAGER see only their own department
        final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
        if (selectedDepartment == 'الكل' || selectedDepartment == null) {
          selectedDepartment = dept;
        }
        return [dept];

      case 'GENERAL_MANAGER':
      case 'SECTOR_MANAGER':
        // These roles see ALL departments
        return ['الكل', ...allDepartments];

      default:
        return ['الكل'];
    }
  }

  /// Returns the assignee list based on role and selected department.
  List<String> _buildAssigneeList({
    required String userRole,
    required String userUsername,
    required String userDepartment,
    required List<Map<String, String>> allUsers, // [{username, department}]
  }) {
    // Helper: strip blocked accounts
    bool isAllowed(String username) => !_blockedUsernames.contains(username);

    switch (userRole) {
      case 'USER':
        // USER can only see themselves — no choice
        return [userUsername];

      case 'ADMIN':
      case 'MANAGER':
        // See only users in their own department
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
        // See users filtered by currently selected department
        if (selectedDepartment == 'الكل' || selectedDepartment == null) {
          // All users across all departments
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

  List<DailyTaskModel> getFilteredData(
    List<DailyTaskModel> tasks, {
    required String userRole,
    required String userUsername,
    required String userDepartment,
    required List<Map<String, String>> allUsers,
  }) {
    return tasks.where((task) {
      // ── Role-based base filter ────────────────────────────────────────────
      // USER: only sees tasks assigned TO them
      if (userRole == 'USER' && task.assignedTo != userUsername) return false;

      // ADMIN / MANAGER: only see tasks in their department
      if ((userRole == 'ADMIN' || userRole == 'MANAGER')) {
        final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
        final taskOwner = allUsers.firstWhere(
          (u) => u['username'] == task.assignedTo,
          orElse: () => {'department': ''},
        );
        if (taskOwner['department'] != dept) return false;
      }

      // ── User-selected filters ─────────────────────────────────────────────
      if (startDate != null || endDate != null) {
        final taskDate = task.createdAt;
        if (startDate != null && taskDate.isBefore(startDate!)) return false;
        if (endDate != null &&
            taskDate.isAfter(endDate!.add(const Duration(days: 1))))
          return false;
      }

      if (selectedAssignee != null && selectedAssignee != 'الكل') {
        if (task.assignedTo != selectedAssignee) return false;
      }

      if (selectedApplication != null && selectedApplication != 'الكل') {
        if (task.appName != selectedApplication) return false;
      }

      if (selectedVisitPlace != null && selectedVisitPlace != 'الكل') {
        if (task.visitPlace != selectedVisitPlace) return false;
      }

      if (selectedStatus != null && selectedStatus != 'الكل') {
        final taskStatusString = task.taskStatus ? 'معلق' : 'مكتمل';
        if (taskStatusString != selectedStatus) return false;
      }

      if (selectedIsRemote != null && selectedIsRemote != 'الكل') {
        final isRemoteString =
            (task.isRemote ?? false) ? 'عن بعد' : 'فى الموقع';
        if (isRemoteString != selectedIsRemote) return false;
      }

      return true;
    }).toList();
  }

  void _clearFilters({
    required String userRole,
    required String userDepartment,
    required String userUsername,
  }) {
    setState(() {
      startDate = null;
      endDate = null;
      selectedApplication = 'الكل';
      selectedVisitPlace = 'الكل';
      selectedStatus = 'الكل';
      selectedIsRemote = 'الكل';

      // Reset assignee respecting role
      if (userRole == 'USER') {
        selectedAssignee = userUsername;
      } else {
        selectedAssignee = 'الكل';
      }

      // Reset department respecting role
      if (userRole == 'USER' || userRole == 'ADMIN' || userRole == 'MANAGER') {
        selectedDepartment = userDepartment.isEmpty ? 'IT' : userDepartment;
      } else {
        selectedDepartment = 'الكل';
      }
    });

    ReusableToast.showToast(
      message: 'تم مسح التختصيصات',
      bgColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return ResponsiveScaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        title: const Text('تقرير المهام اليومية'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.5),
            ),
          ),
        ),
        actions: [
          Consumer<DailyTaskProvider>(
            builder: (context, taskProvider, child) {
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

              final filteredData = getFilteredData(
                taskProvider.tasks,
                userRole: userRole,
                userUsername: userUsername,
                userDepartment: userDepartment,
                allUsers: allUsers,
              );

              return IconButton(
                icon: const Icon(Icons.download_rounded, size: 22),
                onPressed: filteredData.isEmpty
                    ? null
                    : () {
                        generatePDF(
                          filteredData: filteredData,
                          startDate: startDate,
                          endDate: endDate,
                          selectedStatus: selectedStatus,
                          selectedAssignee: selectedAssignee,
                          selectedApplication: selectedApplication,
                          selectedVisitPlace: selectedVisitPlace,
                          selectedIsRemote: selectedIsRemote,
                        );
                        ReusableToast.showToast(
                          message: 'تم تنزيل التقرير بنجاح pdf',
                          bgColor: Colors.green,
                          textColor: Colors.white,
                          fontSize: 16,
                        );
                      },
                tooltip: 'تنزيل التقرير بنجاح pdf',
              );
            },
          ),
        ],
      ),
      body: ResponsiveContentContainer(
        child: Consumer<DailyTaskProvider>(
          builder: (context, taskProvider, child) {
            final tasks = taskProvider.tasks;
            final userProvider = context.read<UserProvider>();
            final aboutAppProvider = context.read<AboutAppProvider>();
            final placeProvider = context.read<PlaceNameProvider>();

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

            // ── Build role-aware lists ─────────────────────────────────────────
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

            // For USER role, force selectedAssignee to themselves
            if (userRole == 'USER') {
              selectedAssignee = userUsername;
            }

            // Guard: if current selectedAssignee is no longer in list, reset
            if (!assigneeList.contains(selectedAssignee)) {
              selectedAssignee = assigneeList.first;
            }

            final appNames = aboutAppProvider.aboutApps
                .map((a) => a.appName)
                .toSet()
                .toList();
            final visitPlaceNames = placeProvider.placeNameStrings;

            final applicationList = ['الكل', ...appNames];
            final visitPlaceList = ['الكل', ...visitPlaceNames];

            final filteredData = getFilteredData(
              tasks,
              userRole: userRole,
              userUsername: userUsername,
              userDepartment: userDepartment,
              allUsers: allUsers,
            );

            final isLoading = taskProvider.isLoading ||
                userProvider.isLoading ||
                aboutAppProvider.isLoading ||
                placeProvider.isLoading;

            if (isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تحميل التقرير...',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isFilterExpanded = !_isFilterExpanded;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.filter_alt_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'تخصيص بحث',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    AnimatedRotation(
                                      turns: _isFilterExpanded ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              firstChild: Container(),
                              secondChild: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDateField(
                                            label: 'من تاريخ',
                                            date: startDate,
                                            onTap: () =>
                                                _selectDate(context, true),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildDateField(
                                            label: 'إلى تاريخ',
                                            date: endDate,
                                            onTap: () =>
                                                _selectDate(context, false),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDropdown(
                                            label: 'مخصص للموظف',
                                            value: assigneeList
                                                    .contains(selectedAssignee)
                                                ? selectedAssignee!
                                                : assigneeList.first,
                                            items: assigneeList,
                                            icon: Icons.person_outline_rounded,
                                            onChanged: userRole == 'USER'
                                                ? null
                                                : (value) {
                                                    setState(() =>
                                                        selectedAssignee =
                                                            value);
                                                  },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildDropdown(
                                            label: 'التطبيق/الجهاز',
                                            value: applicationList.contains(
                                                    selectedApplication)
                                                ? selectedApplication!
                                                : 'الكل',
                                            items: applicationList,
                                            icon: Icons.apps_rounded,
                                            onChanged: (value) {
                                              setState(() =>
                                                  selectedApplication = value);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        if (userRole != 'USER')
                                          Expanded(
                                            child: _buildDropdown(
                                              label: 'الادارة',
                                              value: departmentList.contains(
                                                      selectedDepartment)
                                                  ? selectedDepartment!
                                                  : departmentList.first,
                                              items: departmentList,
                                              icon: Icons.business_rounded,
                                              onChanged: (userRole == 'ADMIN' ||
                                                      userRole == 'MANAGER')
                                                  ? null
                                                  : (value) {
                                                      setState(() {
                                                        selectedDepartment =
                                                            value;
                                                        selectedAssignee =
                                                            'الكل';
                                                      });
                                                    },
                                            ),
                                          ),
                                        if (userRole != 'USER')
                                          const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildDropdown(
                                            label: 'مكان الصيانة',
                                            value: visitPlaceList.contains(
                                                    selectedVisitPlace)
                                                ? selectedVisitPlace!
                                                : 'الكل',
                                            items: visitPlaceList,
                                            icon: Icons.location_on_rounded,
                                            onChanged: (value) {
                                              setState(() =>
                                                  selectedVisitPlace = value);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatusDropdown(
                                            label: 'الحالة',
                                            value: statusList
                                                    .contains(selectedStatus)
                                                ? selectedStatus!
                                                : 'الكل',
                                            items: statusList,
                                            onChanged: (value) {
                                              setState(
                                                  () => selectedStatus = value);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildIsRemoteDropdown(
                                            label: 'نوع الصيانة',
                                            value: isRemoteList
                                                    .contains(selectedIsRemote)
                                                ? selectedIsRemote!
                                                : 'الكل',
                                            items: isRemoteList,
                                            onChanged: (value) {
                                              setState(() =>
                                                  selectedIsRemote = value);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _clearFilters(
                                              userRole: userRole,
                                              userDepartment: userDepartment,
                                              userUsername: userUsername,
                                            ),
                                            icon:
                                                const Icon(Icons.clear_rounded),
                                            label: const Text(''),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              foregroundColor:
                                                  Colors.grey.shade700,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              crossFadeState: _isFilterExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Stats row ───────────────────────────────────────────────
                    if (filteredData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: isDesktop
                                  ? null
                                  : (MediaQuery.of(context).size.width - 44) /
                                      3,
                              child: _buildStatCard(
                                'إجمالي المهام',
                                filteredData.length.toString(),
                                Theme.of(context).colorScheme.primary,
                                Icons.list_alt_rounded,
                              ),
                            ),
                            SizedBox(
                              width: isDesktop
                                  ? null
                                  : (MediaQuery.of(context).size.width - 44) /
                                      3,
                              child: _buildStatCard(
                                'مكتملة',
                                filteredData
                                    .where((t) => !t.taskStatus)
                                    .length
                                    .toString(),
                                Colors.green,
                                Icons.check_circle_outline_rounded,
                              ),
                            ),
                            SizedBox(
                              width: isDesktop
                                  ? null
                                  : (MediaQuery.of(context).size.width - 44) /
                                      3,
                              child: _buildStatCard(
                                'معلقة',
                                filteredData
                                    .where((t) => t.taskStatus)
                                    .length
                                    .toString(),
                                Colors.orange,
                                Icons.pending_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // ── Task list ───────────────────────────────────────────────
                    SizedBox(
                      height: 400,
                      child: filteredData.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredData.length,
                              itemBuilder: (context, index) {
                                final task = filteredData[index];
                                return _buildTaskCard(task, index);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      drawer: null,
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy').format(date)
                        : 'Select Date',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?)? onChanged, // nullable = locked/disabled
  }) {
    final isDisabled = onChanged == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade50 : null,
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              // Passing null to onChanged disables the dropdown natively
              onChanged: onChanged,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color:
                      isDisabled ? Colors.grey.shade300 : Colors.grey.shade600),
              style: TextStyle(
                fontSize: 12,
                color: isDisabled
                    ? Colors.grey.shade400
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontFamily: 'Cairo',
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
                        child: Text(item,
                            overflow: TextOverflow.ellipsis, maxLines: 1),
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

  Widget _buildStatusDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(fontSize: 12))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIsRemoteDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: const TextStyle(fontSize: 12))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(DailyTaskModel task, int index) {
    final status = task.taskStatus ? 'معلق' : 'مكتمل';
    final date = DateFormat('MMM dd, yyyy').format(task.createdAt);
    final isRemote = (task.isRemote ?? false) ? 'عن بعد' : 'فى الموقع';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.taskTitle,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getStatusColor(status)),
                            ),
                            const SizedBox(width: 6),
                            Text(status,
                                style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.apps_rounded, task.appName,
                      const Color(0xFF2196F3)),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.person, task.assignedBy,
                      const Color.fromARGB(255, 25, 109, 225)),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.person_outline_rounded, task.assignedTo,
                      const Color(0xFF64748B)),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today_rounded, date,
                      const Color(0xFF60048B)),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.home_work_rounded, isRemote,
                      const Color(0xFF69948B)),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.group,
                    task.coOperator.isNotEmpty
                        ? '${task.coOperator.toString().replaceAll('[', ' ').replaceAll(']', ' ')} Co-Operators'
                        : 'No Co-Operators',
                    const Color(0xFF69948B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle),
              child: Icon(Icons.search_off_rounded,
                  size: 50, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 10),
            Text('لا توجد نتائج',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('لا يوجد نتائج للبحث الخاص بك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مكتمل':
        return Colors.green;
      case 'معلق':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
