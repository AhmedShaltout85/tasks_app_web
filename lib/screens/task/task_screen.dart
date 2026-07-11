import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/custom_widgets/custom_bottom_sheet.dart';
import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_form_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/common_widgets/responsive/top_nav_bar.dart';
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

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String? selectedEmployee;
  String? selectedApp;
  bool? isActiveFilter;
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
        // Read selected index from route arguments
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null && args['selectedIndex'] != null) {
          setState(() {
            _selectedDrawerIndex = args['selectedIndex'] as int;
          });
        }
        _fetchData();
      });
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    // Already checked in initState callback
    try {
      await _fetchDataImpl();
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> _fetchDataImpl() async {
    if (!mounted) return;

    try {
      log('TaskScreen: _fetchData started');
      final hasConnection = await _connectivity.hasConnection();
      if (!hasConnection) {
        log('TaskScreen: No connection');
        ConnectionDialogService.showNoInternetDialog(
          context,
          onRetry: _fetchDataImpl,
        );
        return;
      }
      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      final department = userProvider.currentUser?.department;
      log('TaskScreen: User department: $department');

      // Step 1: Fetch tasks
      log('Step1: Fetching tasks...');
      await context.read<DailyTaskProvider>().fetchAllTasks();
      if (!mounted) return;
      log('Step1: Tasks done');

      // Step 2: Fetch users
      if (department != null && department.isNotEmpty) {
        log('Step2: Fetching users for $department...');
        await userProvider.fetchUsersByDepartment(department);
        if (!mounted) return;
        log('Step2: Users done');

        // Step 3: Fetch apps
        log('Step3: Fetching apps...');
        final aboutProvider = context.read<AboutAppProvider>();
        await aboutProvider.fetchAppsByDepartment(department);
        if (!mounted) return;
        log('Step3: Apps done');
      }

      // Step 4: Fetch places
      log('Step4: Fetching places...');
      await context.read<PlaceNameProvider>().fetchPlaceNameStrings();
      if (!mounted) return;
      log('Step4: Places done');

      log('TaskScreen: ALL COMPLETE!');
    } catch (e, stack) {
      log('ERROR in _fetchData: $e');
      log('Stack: $stack');
    }
  }

  Future<void> _createTask(Map<String, dynamic> values) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _createTask(values),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    int daysUntilDue = int.tryParse(values['توقع انتهاء المهمة'] ?? '7') ?? 7;

    // Filter out the selected assignee from co-operators
    final assignedTo = values['مخصصة ل'] ?? '';
    List<dynamic> coOperators = values['المتعاونون'] ?? [];
    // ignore: unnecessary_type_check
    if (coOperators is List) {
      coOperators = coOperators.where((op) => op != assignedTo).toList();
    }

    final newTask = DailyTaskModel(
      taskTitle: values['اسم المهمة'] ?? '',
      taskStatus: true,
      appName: values['المنظومة'] ?? '',
      visitPlace: values['المكان الرئيسى'] ?? '',
      subPlace: values['مكان فرعى'] ?? '',
      assignedTo: assignedTo,
      assignedBy: currentUser?.username ?? '',
      coOperator: coOperators,
      expectedCompletionDate: DateTime.now().add(Duration(days: daysUntilDue)),
      taskPriority: values['أهمية المهمة'] ?? 'MEDIUM',
      taskNote: values['ملاحظات'] ?? 'none',
      isRemote: false,
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

  List<dynamic> getFilteredTasks(List<dynamic> tasks) {
    return tasks.where((task) {
      try {
        if (selectedEmployee != null && selectedEmployee!.isNotEmpty) {
          final taskEmployee = task.assignedTo?.toString() ?? '';
          if (taskEmployee != selectedEmployee) return false;
        }

        if (selectedApp != null && selectedApp!.isNotEmpty) {
          final taskApp = task.appName?.toString() ?? '';
          if (taskApp != selectedApp) return false;
        }

        if (isActiveFilter != null) {
          final taskActive = task.taskStatus ?? true;
          if (taskActive != isActiveFilter) return false;
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
      selectedEmployee = null;
      selectedApp = null;
      isActiveFilter = null;
    });
  }

  bool get hasActiveFilters =>
      selectedEmployee != null || selectedApp != null || isActiveFilter != null;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    final userProvider = context.watch<UserProvider>();
    final aboutAppProvider = context.watch<AboutAppProvider>();
    final placeNameProvider = context.watch<PlaceNameProvider>();

    //Filter out the admin
    List<String> employeeNames = userProvider.users
        .map(
          (u) => u.role == 'USER' && u.enabled == true ||
                  u.role == 'MANAGER' ||
                  u.role == 'ADMIN'
              ? u.username
              : 'admin',
        )
        .where((username) => username != 'admin' || username != 'manager')
        .toSet()
        // .where((username) => username != 'admin' || username != 'manager')
        .toList();

    // Get unique app names from AboutAppProvider
    List<String> appNames =
        aboutAppProvider.aboutApps.map((a) => a.appName).toSet().toList();

    List<String> placeNames = placeNameProvider.placeNameStrings;

    if (employeeNames.contains('admin') || employeeNames.contains('manager')) {
      employeeNames.remove('admin');
      employeeNames.remove('manager');
    } else {
      employeeNames = ['لاشئ', ...employeeNames];
    }
    List<String> uniqueEmployeeNames = ['لاشئ', ...employeeNames.toSet()];

    return ResponsiveScaffold(
      topNavBar: buildAdminTopNavBar(context, _selectedDrawerIndex),
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
                final currentUsername =
                    userProvider.currentUser?.username ?? '';

                showResponsiveForm(
                  context: context,
                  content: _buildTaskFormContent(
                    appNames: appNames,
                    employeeNames: uniqueEmployeeNames,
                    currentUsername: currentUsername,
                    placeNames: placeNames,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _buildTaskBody(context, isDark, colorScheme, userProvider, appNames, placeNames),
      sidebarContent: buildAppSidebar(
        context: context,
        selectedIndex: _selectedDrawerIndex,
      ),
    );
  }

  Widget _buildTaskFormContent({
    required List<String> appNames,
    required List<String> employeeNames,
    required String currentUsername,
    required List<String> placeNames,
  }) {
    final ladmin = context.read<UserProvider>().currentUser?.username;
    final currentAssigneeNotifier = ValueNotifier<String?>(currentUsername);

    return StatefulBuilder(
      builder: (context, setState) {
        final currentAssignee = currentAssigneeNotifier.value;
        final filteredCoOperators = employeeNames
            .where(
              (name) =>
                  name.isNotEmpty && name != 'لاشئ' && name != currentAssignee,
            )
            .toList();

        final fields = [
          TextFieldConfig(
            key: 'اسم المهمة',
            label: 'اسم المهم',
            hint: 'ادخل اسم المهمة',
            maxLines: 2,
            icon: Icons.title,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'فضلا ادخل اسم المهمة';
              }
              return null;
            },
          ),
          DropdownFieldConfig(
            key: 'المنظومة',
            label: 'أختر التطبيق /الجهاز',
            icon: Icons.apps,
            items: appNames,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'فضلا اختر التطبيق/الجهاز';
              }
              return null;
            },
          ),
          TextFieldConfig(
            key: 'مخصص بواسطة',
            label: 'مخصص بواسطة',
            hint: 'أدخل مخصص المهمه',
            icon: Icons.manage_accounts,
            initialValue: ladmin,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'فضلا ادخل مخصص المهمة';
              }
              return null;
            },
          ),
          DropdownFieldConfig(
            key: 'مخصصة ل',
            label: 'مخصصة ل',
            items: employeeNames
                .where((name) => name != 'لاشئ' && name != currentUsername)
                .toList(),
            icon: Icons.person,
            onChanged: (value) {
              currentAssigneeNotifier.value = value;
              setState(() {});
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'فضلا وجهه المهمة ل';
              }
              return null;
            },
          ),
          DropdownFieldConfig(
            key: 'المكان الرئيسى',
            label: 'المكان الرئيسى',
            icon: Icons.location_on,
            items: placeNames,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'فضلا اختر المكان الرئيسى';
              }
              return null;
            },
          ),
          TextFieldConfig(
            key: 'مكان فرعى',
            label: 'مكان فرعى',
            hint: 'ادخل المكان الفرعى(اختيارى)',
            icon: Icons.location_on_outlined,
          ),
          DropdownFieldConfig(
            key: 'أهمية المهمة',
            label: 'أهمية المهمة',
            items: const ['HIGH', 'MEDIUM', 'LOW'],
            icon: Icons.priority_high,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'فضلا اختر اهمية المهمة';
              }
              return null;
            },
          ),
          MultiSelectDropdownFieldConfig(
            key: 'المتعاونون',
            label: 'المتعاونون',
            items: filteredCoOperators,
            widgetKey: ValueKey(currentAssignee),
            icon: Icons.person,
            hint: 'ادخل المتعاونون(اختيارى)',
            initialValues: const [],
            includeSearch: false,
            includeSelectAll: false,
            isLarge: true,
            boxDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey),
            ),
          ),
          TextFieldConfig(
            key: 'توقع انتهاء المهمة',
            label: 'توقع انتهاء المهمة',
            hint: 'ادخل توقع انتهاء المهمة بالارقام 7',
            icon: Icons.date_range,
            initialValue: '1',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'فضلا ادخل توقع انتهاء المهمة';
              }
              return null;
            },
          ),
          TextFieldConfig(
            key: 'ملاحظات',
            label: 'ملاحظات',
            hint: 'ادخل ملاحظات',
            initialValue: 'لايوجد ملاحظات',
            icon: Icons.note,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'فضلا ادخل ملاحظات';
              }
              return null;
            },
          ),
        ];

        return CustomBottomSheet(
          title: 'بيانات المهمة',
          fields: fields,
          submitButtonText: 'حفظ المهمة',
          onSubmit: (values) async {
            await _createTask(values);
          },
        );
      },
    );
  }

  Future<void> _toggleTaskStatus(
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
      final updatedTask = task.copyWith(taskStatus: !task.taskStatus);
      await provider.updateTask(task.id, updatedTask);
      await provider.fetchAllTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    task.taskStatus ? Icons.check_circle : Icons.info,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    task.taskStatus ? 'تم انهاء المهمة' : 'تفعيل المهمة',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
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
            content: Center(
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error updating task: ${e.toString()}',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
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

  void _showDeleteConfirmation(dynamic task, DailyTaskProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Text('حذف المهمة',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد من حذف هذه المهمة؟',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${task.taskTitle}"',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'هذه العملية لا يمكن التراجع عنها',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'الغاء',
              style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final dialogContext = context;
              Navigator.pop(dialogContext);

              // Show loading indicator
              if (mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('جاري الحذف...'),
                        ],
                      ),
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }

              try {
                // Delete task
                final hasConnection = await _connectivity.hasConnection();
                if (!hasConnection) {
                  // Create a wrapper function

                  await ConnectionDialogService.showNoInternetDialog(
                    context,
                    // onRetry: retryAction,
                  );
                  return;
                }
                final taskId = task.id is int
                    ? task.id
                    : int.tryParse(task.id.toString()) ?? 0;
                await provider.deleteTask(taskId);

                if (mounted) {
                  ScaffoldMessenger.of(dialogContext).hideCurrentSnackBar();
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'تم حذف المهمة بنجاح',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(dialogContext).hideCurrentSnackBar();
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Error deleting task: ${e.toString()}',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ],
                        ),
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
            },
            child: const Text(
              'حذف',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBody(BuildContext context, bool isDark, ColorScheme colorScheme,
      UserProvider userProvider, List<String> appNames, List<String> placeNames) {
    return ResponsiveContentContainer(
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
                              'تخصيص',
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
                                  'حدف المخصصات',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: 250,
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedEmployee,
                                isExpanded: true,
                                dropdownColor: isDark
                                    ? colorScheme.surface
                                    : Colors.white,
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'مخصص للموظف',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person,
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
                                      'كل الموظفين',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: isDark
                                            ? Colors.grey[300]
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  ...context.watch<UserProvider>().users
                                      .map((u) => u.role == 'USER' && u.enabled == true || u.role == 'MANAGER' || u.role == 'ADMIN' ? u.username : 'admin')
                                      .where((username) => username != 'admin' && username != 'manager')
                                      .toSet()
                                      .map((name) {
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
                                    selectedEmployee = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedApp,
                                isExpanded: true,
                                dropdownColor: isDark
                                    ? colorScheme.surface
                                    : Colors.white,
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'المنظومة',
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
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            color: isDark ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.fetchAllTasks();
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
                    subtitle: 'قم بإضافة مهام جديدة +',
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
                  onRefresh: () => provider.fetchAllTasks(),
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
                                Expanded(
                                  child: Material(
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
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Material(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => _showDeleteConfirmation(
                                          task, provider),
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                          size: 28,
                                        ),
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
    );
  }
}
