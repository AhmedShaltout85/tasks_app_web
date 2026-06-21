import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tasks_app/common_widgets/custom_widgets/custom_reusable_bottom_nav_bar.dart';
import 'package:tasks_app/common_widgets/responsive/drawer_items.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/controller/about_app_provider.dart';
import 'package:tasks_app/controller/daily_task_provider.dart';
import 'package:tasks_app/controller/place_name_provider.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/models/user_model.dart';
import 'package:tasks_app/screens/report/preventive_maintenance_report_screen.dart';
import 'package:tasks_app/screens/report/report_screen.dart';
import 'package:tasks_app/screens/settings/settings_screen.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/common_widgets/responsive/empty_state_widget.dart';
import 'package:tasks_app/common_widgets/task_widgets/shared_task_card.dart';
import 'package:tasks_app/services/connectivity_service.dart';
import 'package:tasks_app/utils/app_route.dart';

class ManagerTaskScreen extends StatefulWidget {
  const ManagerTaskScreen({super.key});

  @override
  State<ManagerTaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<ManagerTaskScreen> {
  String? selectedEmployee;
  String? selectedApp;
  bool? isActiveFilter;
  String? selectedDepartment;
  String? selectedFilterDepartment;
  String? selectedUser;
  String? _selectedUserName;
  bool? selectedIsRemote;
  bool showFilters = false;
  final ConnectivityService _connectivity = ConnectivityService();
  bool _hasFetchedData = false;
  bool _initStateScheduled = false;
  int _selectedNavIndex = 0;
  List<UserModel> filteredUsersByDept = [];
  List<String> departmentsList = [];

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
    await _fetchDataImpl();
  }

  Future<void> _fetchDataImpl() async {
    if (!mounted) return;

    try {
      log('ManagerTaskScreen: _fetchData started');
      final hasConnection = await _connectivity.hasConnection();
      if (!hasConnection) {
        ConnectionDialogService.showNoInternetDialog(
          context,
          onRetry: _fetchDataImpl,
        );
        return;
      }

      // Step 1: Fetch tasks
      log('Step1: Fetching tasks...');
      await context.read<DailyTaskProvider>().fetchAllTasks();
      if (!mounted) return;
      log('Step1: Tasks done');

      // Step 2: Fetch apps
      log('Step2: Fetching apps...');
      final aboutProvider = context.read<AboutAppProvider>();
      await aboutProvider.fetchAllAboutApps();
      if (!mounted) return;
      log('Step2: Apps done');

      // Step 3: Fetch places
      log('Step3: Fetching places...');
      await context.read<PlaceNameProvider>().fetchPlaceNameStrings();
      if (!mounted) return;
      log('Step3: Places done');

      // Step 4: Fetch users
      log('Step4: Fetching users...');
      await context.read<UserProvider>().fetchAllUsers();
      if (!mounted) return;
      log('Step4: Users done');

      // Populate departmentsList from all users and set filteredUsersByDept
      final allUsers = context.read<UserProvider>().users;
      setState(() {
        departmentsList = allUsers
            .map((u) => u.department ?? '')
            .where((dept) => dept.isNotEmpty)
            .toSet()
            .toList();
        filteredUsersByDept = allUsers;
      });

      log('ManagerTaskScreen: ALL COMPLETE!');
    } catch (e, stack) {
      log('ERROR in _fetchData: $e');
      log('Stack: $stack');
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
        if (selectedEmployee != null && selectedEmployee!.isNotEmpty) {
          final taskEmployee = task.assignedTo?.toString() ?? '';
          if (taskEmployee != selectedEmployee) return false;
        }

        if (selectedApp != null && selectedApp!.isNotEmpty) {
          final taskApp = task.appName?.toString() ?? '';
          if (taskApp != selectedApp) return false;
        }

        if (selectedDepartment != null && selectedDepartment!.isNotEmpty) {
          final userProvider = context.read<UserProvider>();
          final assignedToUsername = task.assignedTo?.toString() ?? '';
          final user = userProvider.users.cast<dynamic>().firstWhere(
                (u) => u.username == assignedToUsername,
                orElse: () => null,
              );
          final taskDepartment = user?.department?.toString() ?? '';
          if (taskDepartment != selectedDepartment) return false;
        }

        if (selectedUser != null && selectedUser!.isNotEmpty) {
          final taskUser = task.assignedTo?.toString() ?? '';
          if (taskUser != selectedUser) return false;
        }

        if (selectedIsRemote != null) {
          final taskIsRemote = task.isRemote ?? false;
          if (taskIsRemote != selectedIsRemote) return false;
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
      selectedApp = null;
      isActiveFilter = null;
      selectedDepartment = null;
      selectedFilterDepartment = null;
      selectedUser = null;
      _selectedUserName = null;
      selectedIsRemote = null;
      filteredUsersByDept = [];
    });
  }

  bool get hasActiveFilters =>
      selectedApp != null ||
      isActiveFilter != null ||
      selectedDepartment != null ||
      selectedUser != null ||
      selectedIsRemote != null;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    final userProvider = context.watch<UserProvider>();
    final aboutAppProvider = context.watch<AboutAppProvider>();

    // Get unique app names from AboutAppProvider with safe check
    List<String> appNames = aboutAppProvider.aboutApps.isNotEmpty
        ? aboutAppProvider.aboutApps.map((a) => a.appName).toSet().toList()
        : [];

    // Get unique user names from filteredUsersByDept
    List<String> usersNamesList = filteredUsersByDept.isNotEmpty
        ? filteredUsersByDept
            .where(
              (u) => u.role == 'USER' && u.department == selectedDepartment,
            )
            .map((u) => u.username)
            .toSet()
            .toList()
        : [];

    // Get unique department names from state
    List<String> departmentsList =
        this.departmentsList.isNotEmpty ? this.departmentsList : [];

    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return ResponsiveScaffold(
      appBar: _selectedNavIndex == 0 ? _buildAppBar() : null,
      drawer: null,
      sidebarContent: _buildSidebar(
        isDark: isDark,
        colorScheme: colorScheme,
        userProvider: userProvider,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(
              isDark,
              colorScheme,
              userProvider,
              aboutAppProvider,
              appNames,
              usersNamesList,
              departmentsList,
            ),
          ),
          if (!isDesktop)
            CustomReusableBottomNavBar(
              currentIndex: _selectedNavIndex,
              onTap: (index) {
                setState(() {
                  _selectedNavIndex = index;
                });
              },
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'الرئيسية',
                ),
                BottomNavItem(
                  icon: Icons.build_circle_outlined,
                  activeIcon: Icons.build_circle,
                  label: 'تقارير وقائية',
                ),
                BottomNavItem(
                  icon: Icons.assessment_outlined,
                  activeIcon: Icons.assessment,
                  label: 'التقارير',
                ),
                BottomNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'الضبط',
                ),
              ],
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
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
      ],
    );
  }

  Widget _buildSidebar({
    required bool isDark,
    required ColorScheme colorScheme,
    required UserProvider userProvider,
  }) {
    final currentUser = userProvider.currentUser;
    final displayName = currentUser?.displayName ?? '';
    final username = currentUser?.username ?? '';

    return Column(
      children: [
        DrawerHeaderWidget(
          isDark: isDark,
          colorScheme: colorScheme,
          displayName: displayName,
          username: username,
        ),
        Expanded(
          child: DrawerItemsList(
            items: [
              DrawerItem(
                index: 0,
                icon: Icons.home_outlined,
                title: 'المهام اليومية',
                onTap: () {
                  setState(() {
                    _selectedNavIndex = 0;
                  });
                },
              ),
              DrawerItem(
                index: 1,
                icon: Icons.build_circle_outlined,
                title: 'تقارير وقائية',
                onTap: () {
                  setState(() {
                    _selectedNavIndex = 1;
                  });
                },
              ),
              DrawerItem(
                index: 2,
                icon: Icons.assessment_outlined,
                title: 'التقارير',
                onTap: () {
                  setState(() {
                    _selectedNavIndex = 2;
                  });
                },
              ),
              DrawerItem(
                index: 3,
                icon: Icons.settings_outlined,
                title: 'الضبط',
                onTap: () {
                  setState(() {
                    _selectedNavIndex = 3;
                  });
                },
              ),
            ],
            selectedIndex: _selectedNavIndex,
            isDark: isDark,
            colorScheme: colorScheme,
            isSidebar: true,
          ),
        ),
        DrawerLogoutSection(
          isDark: isDark,
          colorScheme: colorScheme,
          onLogout: () async {
            await userProvider.signOut();
            Navigator.of(context).pushReplacementNamed(AppRoute.loginRouteName);
          },
        ),
      ],
    );
  }

  Widget _buildBody(
    bool isDark,
    ColorScheme colorScheme,
    UserProvider userProvider,
    AboutAppProvider aboutAppProvider,
    List<String> appNames,
    List<String> usersNamesList,
    List<String> departmentsList,
  ) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildHomeContent(
          isDark,
          colorScheme,
          userProvider,
          aboutAppProvider,
          appNames,
          usersNamesList,
          departmentsList,
        );
      case 1:
        return const PreventiveMaintenanceReportScreen(embedded: true);
      case 2:
        return const ReportScreen(embedded: true);
      case 3:
        return const SettingsScreen(embedded: true);
      default:
        return _buildHomeContent(
          isDark,
          colorScheme,
          userProvider,
          aboutAppProvider,
          appNames,
          usersNamesList,
          departmentsList,
        );
    }
  }

  Widget _buildHomeContent(
    bool isDark,
    ColorScheme colorScheme,
    UserProvider userProvider,
    AboutAppProvider aboutAppProvider,
    List<String> appNames,
    List<String> usersNamesList,
    List<String> departmentsList,
  ) {
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
                              'تخصيصات',
                              style: TextStyle(
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
                                  style: TextStyle(color: colorScheme.primary),
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
                                dropdownColor:
                                    isDark ? colorScheme.surface : Colors.white,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'التطبيق/الجهاز',
                                  labelStyle: TextStyle(
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
                                      ? colorScheme.surface
                                          .withValues(alpha: 0.5)
                                      : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('كل التطبيقات'),
                                  ),
                                  ...appNames.map((name) {
                                    return DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(name),
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
                            Expanded(
                              child: DropdownButtonFormField<bool?>(
                                initialValue: selectedIsRemote,
                                isExpanded: true,
                                dropdownColor:
                                    isDark ? colorScheme.surface : Colors.white,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'العمل عن بعد',
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.work,
                                    color: colorScheme.primary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? colorScheme.surface
                                          .withValues(alpha: 0.5)
                                      : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<bool?>(
                                    value: null,
                                    child: Text('الكل'),
                                  ),
                                  const DropdownMenuItem<bool?>(
                                    value: true,
                                    child: Text('نعم'),
                                  ),
                                  const DropdownMenuItem<bool?>(
                                    value: false,
                                    child: Text('لا'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedIsRemote = value;
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
                                initialValue: selectedDepartment,
                                isExpanded: true,
                                dropdownColor:
                                    isDark ? colorScheme.surface : Colors.white,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'الادارة',
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.business,
                                    color: colorScheme.primary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? colorScheme.surface
                                          .withValues(alpha: 0.5)
                                      : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('كل الادارات'),
                                  ),
                                  ...departmentsList.map((dept) {
                                    return DropdownMenuItem<String>(
                                      value: dept,
                                      child: Text(dept),
                                    );
                                  }),
                                ],
                                onChanged: (value) async {
                                  String? oldUser = _selectedUserName;
                                  setState(() {
                                    selectedDepartment = value;
                                    selectedFilterDepartment = value;
                                    selectedUser = null;
                                    _selectedUserName = null;
                                  });
                                  if (value != null) {
                                    await userProvider
                                        .fetchUsersByDepartment(value);
                                    setState(() {
                                      filteredUsersByDept = userProvider.users;
                                      selectedUser = null;
                                      _selectedUserName = null;
                                    });
                                  } else {
                                    setState(() {
                                      filteredUsersByDept = [];
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedUserName,
                                isExpanded: true,
                                dropdownColor:
                                    isDark ? colorScheme.surface : Colors.white,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'مخصص للموظف',
                                  labelStyle: TextStyle(
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
                                      ? colorScheme.surface
                                          .withValues(alpha: 0.5)
                                      : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                items: [
                                  ...usersNamesList.map((name) {
                                    return DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(name),
                                    );
                                  }),
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('كل الموظفين'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedUser = value;
                                    _selectedUserName = value;
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
                            fontSize: 16,
                            color: isDark ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.fetchAllTasks();
                          },
                          child: const Text('اعادة المحاولة'),
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

                final filteredTasks = getFilteredTasks(provider.tasks)
                    .where(
                      (task) => task.taskStatus == true,
                    )
                    .toList();

                if (filteredTasks.isEmpty && hasActiveFilters) {
                  return EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'لا توجد نتائج للبحث الحالي',
                    action: TextButton.icon(
                      onPressed: resetFilters,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Filters'),
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
                                  'إظهار ${filteredTasks.length} من ${provider.tasks.length} مهام',
                                  style: TextStyle(
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
                              isOverdue: task.expectedCompletionDate != null &&
                                  task.expectedCompletionDate
                                      .isBefore(DateTime.now()) &&
                                  task.taskStatus == true,
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

  Future<void> _toggleTaskStatus(
    dynamic task,
    DailyTaskProvider provider,
  ) async {
    try {
      final userProvider = context.read<UserProvider>();
      final username = userProvider.currentUser?.username;
      final taskId =
          task.id is int ? task.id : int.tryParse(task.id.toString()) ?? 0;
      final updatedTask = task.copyWith(taskStatus: !task.taskStatus);
      await provider.updateTask(taskId, updatedTask);
      if (username != null) {
        await provider.fetchAllTasks();
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
                    task.taskStatus ? 'المهمة تم تعطيلها' : 'المهمة تم تفعيلها',
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
}
