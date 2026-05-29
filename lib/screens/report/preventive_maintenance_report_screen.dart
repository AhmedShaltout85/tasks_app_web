import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/controller/preventive_provider.dart';
import 'package:tasks_app/controller/about_app_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/controller/place_name_provider.dart';
import 'package:tasks_app/models/preventive_maintenance_model.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/services/connectivity_service.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/screens/report/widgets/preventive_maintenance_export_pdf.dart';

class PreventiveMaintenanceReportScreen extends StatefulWidget {
  final bool embedded;
  const PreventiveMaintenanceReportScreen({super.key, this.embedded = false});

  @override
  State<PreventiveMaintenanceReportScreen> createState() =>
      _PreventiveMaintenanceReportScreenState();
}

class _PreventiveMaintenanceReportScreenState
    extends State<PreventiveMaintenanceReportScreen>
    with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivity = ConnectivityService();

  // ─── Filter state ─────────────────────────────────────────────────────────
  String? selectedUsername;
  String? selectedAppName;
  String? selectedVisitPlace;
  String? selectedDepartment;
  bool? selectedIsRemote; // null = الكل
  DateTime? startDate;
  DateTime? endDate;

  // ─── UI state ─────────────────────────────────────────────────────────────
  bool _isFilterExpanded = true;

  /// Blocked usernames that are system/admin accounts — never shown in assignee list
  static const _blockedUsernames = {
    'admin',
    'gm',
    'manager',
    'manager1',
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ─── Performance helpers ──────────────────────────────────────────────────
  List<PreventiveMaintenanceModel>? _cachedFilteredData;
  List<PreventiveMaintenanceModel>? _cachedItems;
  Timer? _debounceTimer;

  // isRemote display options
  final List<String> isRemoteList = ['الكل', 'عن بعد', 'فى الموقع'];

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Default values
    selectedUsername = 'الكل';
    selectedAppName = 'الكل';
    selectedVisitPlace = 'الكل';
    selectedDepartment = 'الكل';
    selectedIsRemote = null;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ─── Helper method to get boolean value from isRemote ─────────────────────

  /// Safely converts isRemote (which could be bool or String) to a boolean
  bool _getIsRemoteBool(dynamic isRemote) {
    if (isRemote == null) return false;
    if (isRemote is bool) return isRemote;
    if (isRemote is String) return isRemote.toLowerCase() == 'true';
    return false;
  }

  // ─── Data fetching ────────────────────────────────────────────────────────

  Future<void> _fetchData() async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      if (!mounted) return;
      ConnectionDialogService.showNoInternetDialog(
        context,
        onRetry: _fetchData,
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final department = userProvider.currentUser?.department;

    if (department != null && department.isNotEmpty) {
      await context.read<AboutAppProvider>().fetchAppsByDepartment(department);
    } else {
      await context.read<AboutAppProvider>().fetchAllAboutApps();
    }

    await context.read<PlaceNameProvider>().fetchPlaceNameStrings();

    final dept = (department == null || department.isEmpty) ? 'IT' : department;
    await context
        .read<PreventiveProvider>()
        .fetchAllPreventiveMaintenanceByDepartment(dept);

    final provider = context.read<PreventiveProvider>();
    if (provider.preventiveMaintenance.isEmpty) {
      await context
          .read<PreventiveProvider>()
          .fetchAllPreventiveMaintenanceByDepartment('IT');
    }

    _clearCache();
  }

  // ─── Cache helpers ────────────────────────────────────────────────────────

  void _clearCache() {
    _cachedFilteredData = null;
    _cachedItems = null;
  }

  void _debouncedFilterUpdate(VoidCallback update) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _clearCache();
      setState(update);
    });
  }

  // ─── Filtering ────────────────────────────────────────────────────────────

  List<PreventiveMaintenanceModel> getFilteredData(
    List<PreventiveMaintenanceModel> items, {
    required String userRole,
    required String userUsername,
    required String userDepartment,
    required List<Map<String, String>> allUsers,
  }) {
    if (_cachedFilteredData != null && _cachedItems == items) {
      return _cachedFilteredData!;
    }
    _cachedItems = items;

    if (items.isEmpty) {
      _cachedFilteredData = [];
      return [];
    }

    final filtered = items.where((item) {
      // ── Role-based base filter ────────────────────────────────────────────
      // USER: only sees tasks assigned TO them
      if (userRole == 'USER' && item.username != userUsername) return false;

      // ADMIN / MANAGER: only see tasks in their department
      if ((userRole == 'ADMIN' || userRole == 'MANAGER')) {
        final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
        final taskOwner = allUsers.firstWhere(
          (u) => u['username'] == item.username,
          orElse: () => {'department': ''},
        );
        if (taskOwner['department'] != dept) return false;
      }

      // ── User-selected filters ─────────────────────────────────────────────
      // Username filter
      if (selectedUsername != null && selectedUsername != 'الكل') {
        if (item.username != selectedUsername) return false;
      }

      // Department filter
      if (selectedDepartment != null && selectedDepartment != 'الكل') {
        if (item.department != selectedDepartment) return false;
      }

      // Date range
      if (startDate != null) {
        if (item.createdAt == null) return false;
        if (item.createdAt!
            .isBefore(startDate!.subtract(const Duration(days: 1)))) {
          return false;
        }
      }
      if (endDate != null) {
        if (item.createdAt == null) return false;
        if (item.createdAt!.isAfter(endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // App name
      if (selectedAppName != null && selectedAppName != 'الكل') {
        if (item.appName != selectedAppName) return false;
      }

      // Visit place name
      if (selectedVisitPlace != null && selectedVisitPlace != 'الكل') {
        if (item.placeName != selectedVisitPlace) return false;
      }

      // Remote / on-site
      if (selectedIsRemote != null) {
        final itemIsRemote = _getIsRemoteBool(item.isRemote);
        if (itemIsRemote != selectedIsRemote) return false;
      }

      return true;
    }).toList();

    _cachedFilteredData = filtered;
    return filtered;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool? _isRemoteStringToBool(String? value) {
    if (value == null || value == 'الكل') return null;
    return value == 'عن بعد';
  }

  String _isRemoteBoolToString(bool? value) {
    if (value == null) return 'الكل';
    return value ? 'عن بعد' : 'فى الموقع';
  }

  /// Returns the department list based on role.
  List<String> _buildDepartmentList({
    required String userRole,
    required String userDepartment,
    required List<String> allDepartments,
  }) {
    switch (userRole) {
      case 'USER':
        // USER sees only their own department — lock it
        final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
        return [dept];

      case 'ADMIN':
      case 'MANAGER':
        // ADMIN / MANAGER see only their own department
        final dept = userDepartment.isEmpty ? 'IT' : userDepartment;
        return [dept];

      case 'GENERAL_MANAGER':
      case 'SECTOR_MANAGER':
        // These roles see ALL departments
        return ['الكل', ...allDepartments];

      default:
        return ['الكل'];
    }
  }

  /// Returns the username list based on role and selected department.
  List<String> _buildUsernameList({
    required String userRole,
    required String userUsername,
    required String userDepartment,
    required List<Map<String, String>> allUsers,
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

  void _clearFilters({
    required String userRole,
    required String userDepartment,
    required String userUsername,
  }) {
    _debouncedFilterUpdate(() {
      startDate = null;
      endDate = null;
      selectedAppName = 'الكل';
      selectedVisitPlace = 'الكل';
      selectedIsRemote = null;

      // Reset username respecting role
      if (userRole == 'USER') {
        selectedUsername = userUsername;
      } else {
        selectedUsername = 'الكل';
      }

      // Reset department respecting role
      if (userRole == 'USER' || userRole == 'ADMIN' || userRole == 'MANAGER') {
        selectedDepartment = userDepartment.isEmpty ? 'IT' : userDepartment;
      } else {
        selectedDepartment = 'الكل';
      }
    });

    ReusableToast.showToast(
      message: 'تم مسح التخصيصات',
      bgColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      _debouncedFilterUpdate(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  // ─── Filter Widgets ───────────────────────────────────────────────────────

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
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
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
    final uniqueItems = items.fold<List<String>>([], (acc, e) {
      if (!acc.contains(e)) acc.add(e);
      return acc;
    });
    final safeValue = uniqueItems.contains(value)
        ? value
        : (uniqueItems.isNotEmpty ? uniqueItems.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
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
              value: safeValue,
              isExpanded: true,
              icon: Icon(
                isDisabled
                    ? Icons.lock_outline_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600,
                size: 18,
              ),
              style: TextStyle(
                fontSize: 12,
                color: isDisabled
                    ? Colors.grey.shade500
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontFamily: 'Cairo',
              ),
              items: uniqueItems.map((item) {
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
    final uniqueItems = items.fold<List<String>>([], (acc, e) {
      if (!acc.contains(e)) acc.add(e);
      return acc;
    });
    final safeValue = uniqueItems.contains(value)
        ? value
        : (uniqueItems.isNotEmpty ? uniqueItems.first : null);

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
              value: safeValue,
              isExpanded: true,
              items: uniqueItems
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
              onChanged: (val) => _debouncedFilterUpdate(() => onChanged(val)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Stat & List Widgets ──────────────────────────────────────────────────

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
              offset: const Offset(0, 4)),
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

  Widget _buildCard(PreventiveMaintenanceModel item, int index) {
    final bool isRemoteValue = _getIsRemoteBool(item.isRemote);
    final date = item.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(item.createdAt!)
        : '';

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
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.appName ?? '',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isRemoteValue ? Colors.blue : Colors.orange)
                            .withValues(alpha: 0.1),
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
                              color:
                                  isRemoteValue ? Colors.blue : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isRemoteValue ? 'عن بعد' : 'فى الموقع',
                            style: TextStyle(
                              color:
                                  isRemoteValue ? Colors.blue : Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person, item.username ?? '', Colors.blue),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_rounded, item.placeName ?? '',
                    Colors.red),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  date,
                  const Color(0xFF60048B),
                ),
                if (item.action.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      Icons.repartition_sharp, item.action, Colors.red),
                ],
              ],
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.currentUser?.role == 'ADMIN' ||
        userProvider.currentUser?.role == 'MANAGER';
    final selectedIndex = isAdmin ? 6 : 3;

    return ResponsiveScaffold(
      sidebarContent: widget.embedded
          ? null
          : buildAppSidebar(
              context: context,
              selectedIndex: selectedIndex,
            ),
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        actions: [
          Consumer<PreventiveProvider>(
            builder: (context, provider, child) {
              final userProvider = context.read<UserProvider>();
              final currentUser = userProvider.currentUser;
              final userRole = currentUser?.role ?? '';
              final userUsername = currentUser?.username ?? '';
              final userDepartment = currentUser?.department ?? '';
              final allUsers = userProvider.users
                  .map((u) => ({
                        'username': u.username,
                        'department': u.department ?? '',
                      }))
                  .toList();

              final filteredData = getFilteredData(
                provider.preventiveMaintenance,
                userRole: userRole,
                userUsername: userUsername,
                userDepartment: userDepartment,
                allUsers: allUsers,
              );

              return IconButton(
                icon: Icon(Icons.download_rounded,
                    size: 22, color: colorScheme.onSurface),
                onPressed: filteredData.isEmpty
                    ? null
                    : () async {
                        ReusableToast.showToast(
                          message: 'جاري إنشاء PDF',
                          bgColor: Colors.blue,
                          textColor: Colors.white,
                          fontSize: 14,
                        );
                        try {
                          await generatePreventiveMaintenancePDF(
                            filteredData: filteredData,
                            selectedUsername: selectedUsername,
                            selectedAppName: selectedAppName,
                            selectedPlaceName: selectedVisitPlace,
                            selectedIsRemote: selectedIsRemote,
                            startDate: startDate,
                            endDate: endDate,
                          );
                          final hasConnection =
                              await _connectivity.hasConnection();
                          if (!hasConnection && mounted) {
                            await ConnectionDialogService.showNoInternetDialog(
                                context);
                          }
                        } catch (e) {
                          ReusableToast.showToast(
                            message: 'خطأ في إنشاء PDF: $e',
                            bgColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 14,
                          );
                        }
                      },
                tooltip: 'تحميل تقرير',
              );
            },
          ),
        ],
      ),
      body: ResponsiveContentContainer(
        child: Consumer4<PreventiveProvider, AboutAppProvider, UserProvider,
            PlaceNameProvider>(
          builder: (context, preventiveProvider, aboutAppProvider, userProvider,
              placeProvider, child) {
            // ── Current user info ───────────────────────────────────────────
            final currentUser = userProvider.currentUser;
            final userRole = currentUser?.role ?? '';
            final userUsername = currentUser?.username ?? '';
            final userDepartment = (currentUser?.department?.isEmpty ?? true)
                ? 'IT'
                : currentUser!.department!;

            final allUsers = userProvider.users
                .map((u) => ({
                      'username': u.username,
                      'department': u.department ?? '',
                    }))
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

            final usernameList = _buildUsernameList(
              userRole: userRole,
              userUsername: userUsername,
              userDepartment: userDepartment,
              allUsers: allUsers,
            );

            // For USER role, force selectedUsername to themselves
            if (userRole == 'USER') {
              selectedUsername = userUsername;
            }

            // Guard: if current selectedUsername is no longer in list, reset
            if (!usernameList.contains(selectedUsername)) {
              selectedUsername = usernameList.first;
            }

            // Guard: if current selectedDepartment is no longer in list, reset
            if (!departmentList.contains(selectedDepartment)) {
              selectedDepartment = departmentList.first;
            }

            // App / place lists
            final appNames = aboutAppProvider.aboutApps
                .map((a) => a.appName)
                .where((n) => n.isNotEmpty)
                .toSet()
                .toList();
            final placeNames = placeProvider.placeNameStrings
                .where((p) => p != 'الكل')
                .toSet()
                .toList();

            final appList = ['الكل', ...appNames.where((a) => a != 'الكل')];
            final placeList = ['الكل', ...placeNames];

            // ── Resolve safe dropdown values ────────────────────────────────
            final safeDepartment = departmentList.contains(selectedDepartment)
                ? selectedDepartment!
                : (departmentList.isNotEmpty ? departmentList.first : 'الكل');

            final safeUsername = usernameList.contains(selectedUsername)
                ? selectedUsername!
                : (usernameList.isNotEmpty ? usernameList.first : 'الكل');

            final safeAppName =
                appList.contains(selectedAppName) ? selectedAppName! : 'الكل';

            final safePlaceName = placeList.contains(selectedVisitPlace)
                ? selectedVisitPlace!
                : 'الكل';

            final safeIsRemote = _isRemoteBoolToString(selectedIsRemote);

            // Determine which dropdowns are locked based on role
            final isDepartmentLocked = (userRole == 'USER' ||
                userRole == 'ADMIN' ||
                userRole == 'MANAGER');

            final isUsernameLocked = (userRole == 'USER');

            // ── Loading state ───────────────────────────────────────────────
            final isLoading = preventiveProvider.isLoadingMaintenance ||
                aboutAppProvider.isLoading ||
                placeProvider.isLoading;

            if (isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('تحميل التقرير...',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              );
            }

            final items = preventiveProvider.preventiveMaintenance;
            final filteredData = getFilteredData(
              items,
              userRole: userRole,
              userUsername: userUsername,
              userDepartment: userDepartment,
              allUsers: allUsers,
            );

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Filter Card ───────────────────────────────────────────
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
                            // ── Header ──────────────────────────────────────
                            InkWell(
                              onTap: () => setState(
                                  () => _isFilterExpanded = !_isFilterExpanded),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant,
                                          width: 1)),
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
                                      child: Icon(Icons.filter_alt_rounded,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('تخصيص بحث',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    const Spacer(),
                                    AnimatedRotation(
                                      turns: _isFilterExpanded ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── Filter Body ───────────────────────────────
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
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
                                            label: 'المستخدم',
                                            value: safeUsername,
                                            items: usernameList,
                                            icon: Icons.person_outline_rounded,
                                            onChanged: isUsernameLocked
                                                ? null
                                                : (value) {
                                                    _debouncedFilterUpdate(() {
                                                      selectedUsername = value;
                                                    });
                                                  },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildDropdown(
                                            label: 'التطبيق/الجهاز',
                                            value: safeAppName,
                                            items: appList,
                                            icon: Icons.apps_rounded,
                                            onChanged: (value) {
                                              _debouncedFilterUpdate(() {
                                                selectedAppName = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDropdown(
                                            label: 'الادارة',
                                            value: safeDepartment,
                                            items: departmentList,
                                            icon: Icons.business_rounded,
                                            onChanged: isDepartmentLocked
                                                ? null
                                                : (value) {
                                                    _debouncedFilterUpdate(() {
                                                      selectedDepartment =
                                                          value;
                                                      selectedUsername = 'الكل';
                                                    });
                                                  },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildDropdown(
                                            label: 'مكان الزيارة',
                                            value: safePlaceName,
                                            items: placeList,
                                            icon: Icons.location_on_rounded,
                                            onChanged: (value) {
                                              _debouncedFilterUpdate(() {
                                                selectedVisitPlace = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildIsRemoteDropdown(
                                            label: 'نوع الصيانة',
                                            value: safeIsRemote,
                                            items: isRemoteList,
                                            onChanged: (value) {
                                              _debouncedFilterUpdate(() {
                                                selectedIsRemote =
                                                    _isRemoteStringToBool(
                                                        value);
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
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

                    // ── Stats Row ─────────────────────────────────────────────
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
                                'عن بعد',
                                filteredData
                                    .where((i) =>
                                        _getIsRemoteBool(i.isRemote) == true)
                                    .length
                                    .toString(),
                                Colors.blue,
                                Icons.home_work_rounded,
                              ),
                            ),
                            SizedBox(
                              width: isDesktop
                                  ? null
                                  : (MediaQuery.of(context).size.width - 44) /
                                      3,
                              child: _buildStatCard(
                                'فى الموقع',
                                filteredData
                                    .where((i) =>
                                        _getIsRemoteBool(i.isRemote) == false)
                                    .length
                                    .toString(),
                                Colors.orange,
                                Icons.location_on_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── List ──────────────────────────────────────────────────
                    SizedBox(
                      height: 400,
                      child: filteredData.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredData.length,
                              itemBuilder: (context, index) =>
                                  _buildCard(filteredData[index], index),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
