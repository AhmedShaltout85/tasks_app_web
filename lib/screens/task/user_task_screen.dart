import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_form_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/controller/about_app_provider.dart';
import 'package:tasks_app/controller/daily_task_provider.dart';
import 'package:tasks_app/controller/place_name_provider.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/models/daily_task_model.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/common_widgets/responsive/empty_state_widget.dart';
import 'package:tasks_app/common_widgets/task_widgets/shared_task_card.dart';
import 'package:tasks_app/services/connectivity_service.dart';

class UserTaskScreen extends StatefulWidget {
  const UserTaskScreen({super.key});

  @override
  State<UserTaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<UserTaskScreen> {
  String? selectedApp;
  String? selectedIsRemote;
  String? selectedPriority;
  bool showFilters = false;
  final ConnectivityService _connectivity = ConnectivityService();
  int _selectedDrawerIndex = 0;
  bool _hasFetchedData = false;
  bool _initStateScheduled = false;

  @override
  void initState() {
    super.initState();
    if (!_initStateScheduled) {
      _initStateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasFetchedData) return;
        _hasFetchedData = true;
        _fetchData();
      });
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    // Already checked in initState callback
    await _fetchDataImpl();
  }

  Future<void> _fetchDataImpl() async {
    if (!mounted) return;

    try {
      log('UserTaskScreen: _fetchData started');
      final hasConnection = await _connectivity.hasConnection();
      if (!hasConnection) {
        log('UserTaskScreen: No connection');
        ConnectionDialogService.showNoInternetDialog(
          context,
          onRetry: _fetchDataImpl,
        );
        return;
      }
      final userProvider = context.read<UserProvider>();
      final username = userProvider.currentUser?.username;
      final department = userProvider.currentUser?.department;
      log('UserTaskScreen: Username: $username, Department: $department');
      // await userProvider.fetchAllUsers();
      await context.read<UserProvider>().fetchUsersByDepartment(
            department ?? '',
          );
      // Step 1: Fetch tasks assigned to current user
      if (username != null) {
        log('Step1: Fetching tasks assigned to $username...');
        await context.read<DailyTaskProvider>().fetchTasksAssignedTo(username);
        if (!mounted) return;
        log('Step1: Tasks done');
      }

      // Step 2: Fetch apps
      if (department != null && department.isNotEmpty) {
        log('Step2: Fetching apps for $department...');
        final aboutProvider = context.read<AboutAppProvider>();
        await aboutProvider.fetchAppsByDepartment(department);
        if (!mounted) return;
        log('Step2: Apps done');
      }

      // Step 3: Fetch places
      log('Step3: Fetching places...');
      await context.read<PlaceNameProvider>().fetchPlaceNameStrings();
      if (!mounted) return;
      log('Step3: Places done');

      log('UserTaskScreen: ALL COMPLETE!');
    } catch (e, stack) {
      log('ERROR in _fetchData: $e');
      log('Stack: $stack');
    }
  }

  // Create a new task
  Future<void> _createTask(Map<String, dynamic> values) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      await ConnectionDialogService.showNoInternetDialog(context);
      return;
    }

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    int daysUntilDue =
        int.tryParse(values['expected-completion-date'] ?? '7') ?? 7;

    final newTask = DailyTaskModel(
      taskTitle: values['task_title'] ?? '',
      taskStatus: true,
      appName: values['app_name'] ?? '',
      visitPlace: values['place_name'] ?? '',
      subPlace: values['sub-place'] ?? '',
      assignedTo: userProvider.currentUser?.username ?? '',
      assignedBy: currentUser?.username ?? '',
      coOperator: values['co_operator_users'] ?? [],
      expectedCompletionDate: DateTime.now().add(Duration(days: daysUntilDue)),
      taskPriority: values['task-priority'] ?? 'HIGH',
      taskNote: values['task-note'] ?? 'لايوجد ملاحظات',
      isRemote: values['is_remote'] ?? false,
      createdAt: DateTime.now(),
    );

    await context.read<DailyTaskProvider>().createTask(newTask);

    if (mounted) {
      final provider = context.read<DailyTaskProvider>();
      if (provider.error != null) {
        ReusableToast.showToast(
          message: provider.error!,
          bgColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16,
        );
        provider.clearError();
      } else {
        ReusableToast.showToast(
          message: 'تم إضافة المهمة بنجاح',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );
        _fetchData();
      }
    }
  }

  // void _showNoInternetDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('لا يوجد اتصال بالانترنت'),
  //       content: const Text(
  //         'يرجى التحقق من الاتصال والمحاولة مرة اخرى',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('حسنا'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  List<dynamic> getFilteredTasks(List<dynamic> tasks) {
    return tasks.where((task) {
      try {
        if (selectedApp != null && selectedApp!.isNotEmpty) {
          final taskApp = task.appName?.toString() ?? '';
          if (taskApp != selectedApp) return false;
        }

        if (selectedIsRemote != null && selectedIsRemote != 'الكل') {
          final taskIsRemote = task.isRemote == true;
          final filterValue = selectedIsRemote == 'عن بعد';
          if (taskIsRemote != filterValue) return false;
        }

        if (selectedPriority != null && selectedPriority != 'الكل') {
          final taskPriority = task.taskPriority?.toString() ?? '';
          final priorityMap = {
            'عالية': 'HIGH',
            'متوسطة': 'MEDIUM',
            'منخفضة': 'LOW',
          };
          final mappedPriority =
              priorityMap[selectedPriority] ?? selectedPriority;
          if (taskPriority != mappedPriority) return false;
        }

        return true;
      } catch (e) {
        log('Error filtering task: $e');
        return true;
      }
    }).toList();
  }

  void resetFilters() {
    setState(() {
      selectedApp = null;
      selectedIsRemote = null;
      selectedPriority = null;
    });
  }

  bool get hasActiveFilters =>
      selectedApp != null ||
      selectedIsRemote != null ||
      selectedPriority != null;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    final userProvider = context.watch<UserProvider>();
    final aboutAppProvider = context.watch<AboutAppProvider>();

    // Get unique app names from AboutAppProvider
    List<String> appNames =
        aboutAppProvider.aboutApps.map((a) => a.appName).toSet().toList();

    List<String> placeNames =
        context.watch<PlaceNameProvider>().placeNameStrings;
    List<String> employeeNames = userProvider.users
        .map((u) => u.role == 'USER' && u.enabled == true ? u.username : 'NULL')
        // .where((username) =>
        //     username != 'admin' ||
        //     username != userProvider.currentUser?.username)
        .toSet()
        .toList();
    employeeNames.remove(userProvider.currentUser?.username);
    employeeNames.remove('NULL');
    log('employeeNames: $employeeNames');

    return ResponsiveScaffold(
      sidebarContent: buildAppSidebar(
        context: context,
        selectedIndex: _selectedDrawerIndex,
      ),
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'تخصيص',
                icon: Icon(Icons.filter_list, color: colorScheme.onSurface),
                onPressed: () {
                  setState(() {
                    showFilters = !showFilters;
                  });
                },
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 8, height: 8),
                  ),
                ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'إضافة مهمة',
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                showResponsiveForm(
                  context: context,
                  title: 'إضافة مهمة جديدة',
                  content:
                      _buildAddTaskForm(appNames, placeNames, employeeNames),
                );
              },
            ),
          ),
        ],
      ),
      body: ResponsiveContentContainer(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: showFilters ? null : 0,
              child: showFilters
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surface : Colors.grey[100],
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'تخصيصات',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (hasActiveFilters)
                                TextButton.icon(
                                  onPressed: resetFilters,
                                  icon: Icon(
                                    Icons.clear_all,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                  label: Text(
                                    'حذف التصفية',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  initialValue: selectedIsRemote,
                                  isExpanded: true,
                                  dropdownColor: isDark
                                      ? colorScheme.surface
                                      : Colors.white,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'نوع الصيانة',
                                    labelStyle: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.location_on,
                                      color: colorScheme.primary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? colorScheme.surface.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text(
                                        'الكل',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'عن بعد',
                                      child: Text(
                                        'عن بعد',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'في الموقع',
                                      child: Text(
                                        'في الموقع',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedIsRemote = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  initialValue: selectedPriority,
                                  isExpanded: true,
                                  dropdownColor: isDark
                                      ? colorScheme.surface
                                      : Colors.white,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'الاولوية',
                                    labelStyle: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.priority_high,
                                      color: colorScheme.primary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? colorScheme.surface.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text(
                                        'الكل',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'عالية',
                                      child: Text(
                                        'عالية',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'متوسطة',
                                      child: Text(
                                        'متوسطة',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'منخفضة',
                                      child: Text(
                                        'منخفضة',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPriority = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedApp,
                                  isExpanded: true,
                                  dropdownColor: isDark
                                      ? colorScheme.surface
                                      : Colors.white,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'التطبيق/الجهاز',
                                    labelStyle: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.apps,
                                      color: colorScheme.primary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? colorScheme.surface.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'كل التطبيقات',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    ...appNames.map((name) {
                                      return DropdownMenuItem<String>(
                                        value: name,
                                        child: Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            color: isDark
                                                ? Colors.grey[300]
                                                : Colors.black87,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedApp = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Consumer<DailyTaskProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.tasks.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${provider.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              provider.fetchTasksAssignedTo(
                                userProvider.currentUser!.username,
                              );
                            },
                            child: const Text(
                              'اعادة المحاولة',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.tasks.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.task_outlined,
                      title: 'لا توجد مهام',
                    );
                  }

                  final filteredTasks = getFilteredTasks(
                    provider.tasks,
                  ).where((task) => task.taskStatus == true).toList();

                  if (filteredTasks.isEmpty && hasActiveFilters) {
                    return EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'لا توجد نتائج للبحث الحالي',
                      action: TextButton.icon(
                        onPressed: resetFilters,
                        icon: const Icon(Icons.clear_all),
                        label: const Text(
                          'حذف الفلترات',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchTasksAssignedTo(
                      userProvider.currentUser!.username,
                    ),
                    color: colorScheme.primary,
                    child: Column(
                      children: [
                        if (hasActiveFilters)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'إظهار ${filteredTasks.length} of ${provider.tasks.length} مهام',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];
                              return SharedTaskCard(
                                task: task,
                                isOverdue: task.expectedCompletionDate
                                        .isBefore(DateTime.now()) &&
                                    task.taskStatus == true,
                                actions: [
                                  Material(
                                    color: task.taskStatus == true
                                        ? Colors.green.shade600
                                        : Colors.grey.shade500,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () =>
                                          _toggleTaskStatus(task, provider),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Icon(
                                          task.taskStatus == true
                                              ? Icons.toggle_on
                                              : Icons.toggle_off,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: task.isRemote == true
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () async {
                                        log('Tapping isRemote button for task ${task.id}');
                                        final provider =
                                            context.read<DailyTaskProvider>();
                                        final taskId = task.id is int
                                            ? task.id
                                            : int.tryParse(
                                                    task.id.toString()) ??
                                                0;
                                        final newIsRemote =
                                            !(task.isRemote ?? false);
                                        log(
                                          'Current isRemote: ${task.isRemote}, New value: $newIsRemote',
                                        );

                                        await provider.updateTask(
                                          taskId,
                                          task.copyWith(isRemote: newIsRemote),
                                        );
                                        log(
                                          'Update complete. Tasks in provider: ${provider.tasks.length}',
                                        );

                                        final username = context
                                            .read<UserProvider>()
                                            .currentUser
                                            ?.username;
                                        if (username != null) {
                                          await provider
                                              .fetchTasksAssignedTo(username);
                                        }

                                        log('After fetch - checking task $taskId:');
                                        for (var t in provider.tasks) {
                                          log('  Task ${t.id}: isRemote=${t.isRemote}');
                                        }

                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    newIsRemote
                                                        ? Icons.home_work
                                                        : Icons.home,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      newIsRemote
                                                          ? 'تم تغيير إلى العمل عن بعد'
                                                          : 'تم تغيير إلى موقع العمل',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  Colors.blue.shade700,
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Icon(
                                          task.isRemote == true
                                              ? Icons.home_work
                                              : Icons.home,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: (task.taskNote != null &&
                                            task.taskNote.isNotEmpty &&
                                            task.taskNote != 'none')
                                        ? Colors.orange.shade600
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => _showTaskNoteDialog(task),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Icon(
                                          Icons.note_alt_outlined,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTaskStatus(
    dynamic task,
    DailyTaskProvider provider,
  ) async {
    try {
      final userProvider = context.read<UserProvider>();
      final username = userProvider.currentUser?.username;
      final updatedTask = task.copyWith(taskStatus: !task.taskStatus);
      await provider.updateTask(task.id, updatedTask);
      if (username != null) {
        await provider.fetchTasksAssignedTo(username);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  task.taskStatus ? Icons.check_circle : Icons.info,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.taskStatus ? 'تم انهاء المهمة' : 'تم تفعيل المهمة',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error updating task: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleRemoteStatus(
    dynamic task,
    DailyTaskProvider provider,
  ) async {
    try {
      final hasConnection = await _connectivity.hasConnection();
      if (!hasConnection) {
        // Create a wrapper function
        await ConnectionDialogService.showNoInternetDialog(context);
        return;
      }
      final userProvider = context.read<UserProvider>();
      final username = userProvider.currentUser?.username;
      final newIsRemote = !(task.isRemote ?? false);
      log('Toggling isRemote from ${task.isRemote} to $newIsRemote');

      final taskId =
          task.id is int ? task.id : int.tryParse(task.id.toString()) ?? 0;
      final updatedTask = task.copyWith(isRemote: newIsRemote);

      await provider.updateTask(taskId, updatedTask);

      if (username != null) {
        await provider.fetchTasksAssignedTo(username);
      }

      log('After fetch - tasks count: ${provider.tasks.length}');
      if (provider.tasks.isNotEmpty) {
        final updatedTaskFromList = provider.tasks.firstWhere(
          (t) => t.id == taskId,
          orElse: () => provider.tasks.first,
        );
        log('Task $taskId isRemote in list: ${updatedTaskFromList.isRemote}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newIsRemote ? Icons.home_work : Icons.home,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    newIsRemote
                        ? 'تم تغيير إلى العمل عن بعد'
                        : 'تم تغيير إلى موقع العمل',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error updating task: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showTaskNoteDialog(dynamic task) {
    final noteController = TextEditingController(text: task.taskNote ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.note_alt_outlined),
            SizedBox(width: 12),
            Text('ملاحظة المهمة', style: TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملاحظة: ${task.taskTitle}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'أضف ملاحظة...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              final hasConnection = await _connectivity.hasConnection();
              if (!hasConnection) {
                await ConnectionDialogService.showNoInternetDialog(context);
                return;
              }
              final newNote = noteController.text.trim();
              final provider = context.read<DailyTaskProvider>();
              final taskId = task.id is int
                  ? task.id
                  : int.tryParse(task.id.toString()) ?? 0;

              await provider.updateTask(
                taskId,
                task.copyWith(taskNote: newNote.isEmpty ? 'none' : newNote),
              );

              final username =
                  context.read<UserProvider>().currentUser?.username;
              if (username != null) {
                await provider.fetchTasksAssignedTo(username);
              }

              if (mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم تحديث الملاحظة',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskForm(
    List<String> appNames,
    List<String> placeNames,
    List<String> employeeNames,
  ) {
    return _AddTaskFormContent(
      appNames: appNames,
      placeNames: placeNames,
      employeeNames: employeeNames,
      onSubmit: (values) async {
        log('Task Title: ${values['task_title']}');
        log('App Name: ${values['app_name']}');
        log('Place Name: ${values['place_name']}');
        log('Sub Place: ${values['sub_place']}');
        log('Is Remote: ${values['is_remote']}');
        log('Co-operator Users: ${values['co_operator_users']}');
        await _createTask(values);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade700,
              content: Center(
                child: Text(
                  'Task added: ${values['task_title']}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class _AddTaskFormContent extends StatefulWidget {
  final List<String> appNames;
  final List<String> placeNames;
  final List<String> employeeNames;
  final Function(Map<String, dynamic>) onSubmit;

  const _AddTaskFormContent({
    required this.appNames,
    required this.placeNames,
    required this.employeeNames,
    required this.onSubmit,
  });

  @override
  State<_AddTaskFormContent> createState() => _AddTaskFormContentState();
}

class _AddTaskFormContentState extends State<_AddTaskFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _taskTitleController = TextEditingController();
  final _subPlaceController = TextEditingController(text: 'لايوجد');
  String? _selectedAppName;
  String? _selectedPlaceName;
  bool _isRemote = false;
  List<String> _selectedCoOperators = [];

  @override
  void initState() {
    super.initState();
    _selectedAppName = 'اختر';
    _selectedPlaceName = 'اختر';
    _selectedCoOperators = List.from(widget.employeeNames);
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _subPlaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _taskTitleController,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'اسم المهمة',
              labelStyle: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              hintText: 'ادخل اسم المهمة',
              prefixIcon: Icon(Icons.title, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'فضلا ادخل اسم المهمة';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedAppName,
            isExpanded: true,
            dropdownColor: isDark ? colorScheme.surface : Colors.white,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'اسم التطبيق',
              labelStyle: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              prefixIcon: Icon(Icons.apps, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: 'اختر',
                child: Text('اختر', style: TextStyle(fontFamily: 'Cairo')),
              ),
              ...widget.appNames.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child:
                      Text(name, style: const TextStyle(fontFamily: 'Cairo')),
                );
              }),
            ],
            onChanged: (value) => setState(() => _selectedAppName = value),
            validator: (value) {
              if (value == null || value.isEmpty || value == 'اختر') {
                return 'فضلا اختر اسم التطبيق';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedPlaceName,
            isExpanded: true,
            dropdownColor: isDark ? colorScheme.surface : Colors.white,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'اسم المكان',
              labelStyle: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              prefixIcon: Icon(Icons.location_on, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: 'اختر',
                child: Text('اختر', style: TextStyle(fontFamily: 'Cairo')),
              ),
              ...widget.placeNames.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child:
                      Text(name, style: const TextStyle(fontFamily: 'Cairo')),
                );
              }),
            ],
            onChanged: (value) => setState(() => _selectedPlaceName = value),
            validator: (value) {
              if (value == null || value.isEmpty || value == 'اختر') {
                return 'فضلا اختر اسم المكان';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _subPlaceController,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'المكان الفرعي',
              labelStyle: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('عن بعد', style: TextStyle(fontFamily: 'Cairo')),
            value: _isRemote,
            onChanged: (value) => setState(() => _isRemote = value),
            secondary: Icon(Icons.wifi, color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            dropdownColor: isDark ? colorScheme.surface : Colors.white,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'المتعاونون',
              labelStyle: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              prefixIcon: Icon(Icons.people, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              DropdownMenuItem<String>(
                value: '__ALL__',
                child: const Text(
                  'اختر الكل',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              ...widget.employeeNames.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    name,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                );
              }),
            ],
            onChanged: (value) {
              if (value == '__ALL__') {
                setState(
                  () => _selectedCoOperators = List.from(widget.employeeNames),
                );
              } else if (value != null) {
                setState(() {
                  if (_selectedCoOperators.contains(value)) {
                    _selectedCoOperators.remove(value);
                  } else {
                    _selectedCoOperators.add(value);
                  }
                });
              }
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _selectedCoOperators.map((user) {
              return Chip(
                label: Text(
                  user,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                ),
                onDeleted: () {
                  setState(() => _selectedCoOperators.remove(user));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSubmit({
                  'task_title': _taskTitleController.text,
                  'app_name':
                      _selectedAppName == 'اختر' ? '' : _selectedAppName ?? '',
                  'place_name': _selectedPlaceName == 'اختر'
                      ? ''
                      : _selectedPlaceName ?? '',
                  'sub_place': _subPlaceController.text,
                  'is_remote': _isRemote,
                  'co_operator_users': _selectedCoOperators,
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'حفظ المهمة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
