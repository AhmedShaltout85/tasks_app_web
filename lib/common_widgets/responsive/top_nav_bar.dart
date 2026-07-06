import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/screens/about_app/manage_about_app_screen.dart';
import 'package:tasks_app/screens/complaints/manage_complmaints_screen.dart';
import 'package:tasks_app/screens/places/manage_place_screen.dart';
import 'package:tasks_app/screens/preventive/preventive_item_screen.dart';
import 'package:tasks_app/screens/preventive/manage_preventive_maintenance_screen.dart';
import 'package:tasks_app/screens/report/preventive_maintenance_report_screen.dart';
import 'package:tasks_app/screens/report/report_screen.dart';
import 'package:tasks_app/screens/settings/settings_screen.dart';
import 'package:tasks_app/screens/task/task_screen.dart';
import 'package:tasks_app/screens/task/user_task_screen.dart';
import 'package:tasks_app/screens/user/manage_user_screen.dart';
import 'package:tasks_app/utils/app_route.dart';

class TopNavItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const TopNavItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

void _navTo(BuildContext context, Widget screen) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => screen),
  );
}

Widget buildAdminTopNavBar(BuildContext context, int selectedIndex) {
  return TopNavBar(
    selectedIndex: selectedIndex,
    items: [
      TopNavItem(
        icon: Icons.home_rounded,
        title: 'الرئيسية',
        onTap: () => _navTo(context, const TaskScreen()),
      ),
      TopNavItem(
        icon: Icons.people_rounded,
        title: 'أدارة المستخدمين',
        onTap: () => _navTo(context, const ManageUserScreen()),
      ),
      TopNavItem(
        icon: Icons.shield_outlined,
        title: 'عناصر وقائية',
        onTap: () => _navTo(context, const PreventiveItemScreen()),
      ),
      TopNavItem(
        icon: Icons.apps_outage,
        title: 'إدارة التطبيقات',
        onTap: () => _navTo(context, const ManageAboutAppScreen()),
      ),
      TopNavItem(
        icon: Icons.location_on_rounded,
        title: 'إدارة المواقع',
        onTap: () => _navTo(context, const ManagePlaceScreen()),
      ),
      TopNavItem(
        icon: Icons.assessment_rounded,
        title: 'التقارير اليومية',
        onTap: () => _navTo(context, const ReportScreen()),
      ),
      TopNavItem(
        icon: Icons.build_circle_outlined,
        title: 'تقارير صيانة وقائية',
        onTap: () => _navTo(context, const PreventiveMaintenanceReportScreen()),
      ),
      TopNavItem(
        icon: Icons.settings_rounded,
        title: 'الضبط والاعدادات',
        onTap: () => _navTo(context, const SettingsScreen()),
      ),
      TopNavItem(
        icon: Icons.report_problem_outlined,
        title: 'شكاوى الموظفين',
        onTap: () => _navTo(context, const ManageComplaintsScreen()),
      ),
    ],
  );
}

Widget buildUserTopNavBar(BuildContext context, int selectedIndex) {
  return TopNavBar(
    selectedIndex: selectedIndex,
    items: [
      TopNavItem(
        icon: Icons.home_rounded,
        title: 'الرئيسية',
        onTap: () => _navTo(context, const UserTaskScreen()),
      ),
      TopNavItem(
        icon: Icons.shield_outlined,
        title: 'عناصر وقائية',
        onTap: () => _navTo(context, const PreventiveItemScreen()),
      ),
      TopNavItem(
        icon: Icons.assessment_rounded,
        title: 'التقارير اليومية',
        onTap: () => _navTo(context, const ReportScreen()),
      ),
      TopNavItem(
        icon: Icons.build_circle_outlined,
        title: 'تقارير صيانة وقائية',
        onTap: () => _navTo(context, const PreventiveMaintenanceReportScreen()),
      ),
      TopNavItem(
        icon: Icons.add_circle_outline,
        title: 'إضافة صيانة وقائية',
        onTap: () => _navTo(context, const ManagePreventiveMaintenanceScreen()),
      ),
      TopNavItem(
        icon: Icons.settings_rounded,
        title: 'الضبط والاعدادات',
        onTap: () => _navTo(context, const SettingsScreen()),
      ),
      TopNavItem(
        icon: Icons.info_outline_rounded,
        title: 'حول التطبيقات',
        onTap: () => _navTo(context, const ManageAboutAppScreen()),
      ),
    ],
  );
}

class TopNavBar extends StatelessWidget {
  final List<TopNavItem> items;
  final int selectedIndex;

  const TopNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    if (!isDesktop) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Image.asset(
              'assets/icons/logo.jpeg',
              height: 50,
              width: 50,
              fit: BoxFit.contain,
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = selectedIndex == index;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected
                                  ? colorScheme.primary
                                  : isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Cairo',
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colorScheme.primary
                                    : isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLogoutDialog(context),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color:
                            isDark ? Colors.red.shade300 : Colors.red.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.red.shade300
                              : Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = context.read<UserProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متاكد أنك تريد تسجيل الخروج؟',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Cairo',
            color: isDark ? Colors.grey.shade300 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'الغاء',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await userProvider.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushReplacementNamed(AppRoute.loginRouteName);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildRoleTopNavBar(BuildContext context, int selectedIndex) {
  final userProvider = Provider.of<UserProvider>(context);
  final role = userProvider.currentUser?.role;
  final isAdmin = role == 'ADMIN' || role == 'MANAGER';
  return isAdmin
      ? buildAdminTopNavBar(context, selectedIndex)
      : buildUserTopNavBar(context, selectedIndex);
}
