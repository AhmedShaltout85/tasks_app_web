import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/responsive/drawer_items.dart';
import 'package:tasks_app/controller/theme_provider.dart';
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

enum SidebarRole { admin, manager, user }

List<DrawerItem> _buildAdminItems(BuildContext context, int selectedIndex) {
  return [
    DrawerItem(
      index: 0,
      icon: Icons.home_rounded,
      title: 'الرئيسية',
      onTap: () => _navigateTo(context, const TaskScreen(), 0),
    ),
    DrawerItem(
      index: 1,
      icon: Icons.people_rounded,
      title: 'أدارة المستخدمين',
      onTap: () => _navigateTo(context, const ManageUserScreen(), 1),
    ),
    DrawerItem(
      index: 2,
      icon: Icons.shield_outlined,
      title: 'عناصر وقائية',
      onTap: () => _navigateTo(context, const PreventiveItemScreen(), 2),
    ),
    DrawerItem(
      index: 3,
      icon: Icons.apps_outage,
      title: 'إدارة التطبيقات',
      onTap: () => _navigateTo(context, const ManageAboutAppScreen(), 3),
    ),
    DrawerItem(
      index: 4,
      icon: Icons.location_on_rounded,
      title: 'إدارة المواقع',
      onTap: () => _navigateTo(context, const ManagePlaceScreen(), 4),
    ),
    DrawerItem(
      index: 5,
      icon: Icons.assessment_rounded,
      title: 'التقارير اليومية',
      onTap: () => _navigateTo(context, const ReportScreen(), 5),
    ),
    DrawerItem(
      index: 6,
      icon: Icons.build_circle_outlined,
      title: 'تقارير صيانة وقائية',
      onTap: () =>
          _navigateTo(context, const PreventiveMaintenanceReportScreen(), 6),
    ),
    DrawerItem(
      index: 7,
      icon: Icons.settings_rounded,
      title: 'الضبط والاعدادات',
      onTap: () => _navigateTo(context, const SettingsScreen(), 7),
    ),
    DrawerItem(
      index: 8,
      icon: Icons.report_problem_outlined,
      title: 'شكاوى الموظفين',
      onTap: () => _navigateTo(context, const ManageComplaintsScreen(), 8),
    ),
  ];
}

List<DrawerItem> _buildUserItems(BuildContext context, int selectedIndex) {
  return [
    DrawerItem(
      index: 0,
      icon: Icons.home_rounded,
      title: 'الرئيسية',
      onTap: () => _navigateTo(context, const UserTaskScreen(), 0),
    ),
    DrawerItem(
      index: 1,
      icon: Icons.shield_outlined,
      title: 'عناصر وقائية',
      onTap: () => _navigateTo(context, const PreventiveItemScreen(), 1),
    ),
    DrawerItem(
      index: 2,
      icon: Icons.assessment_rounded,
      title: 'التقارير اليومية',
      onTap: () => _navigateTo(context, const ReportScreen(), 2),
    ),
    DrawerItem(
      index: 3,
      icon: Icons.build_circle_outlined,
      title: 'تقارير صيانة وقائية',
      onTap: () =>
          _navigateTo(context, const PreventiveMaintenanceReportScreen(), 3),
    ),
    DrawerItem(
      index: 4,
      icon: Icons.add_circle_outline,
      title: 'إضافة صيانة وقائية',
      onTap: () =>
          _navigateTo(context, const ManagePreventiveMaintenanceScreen(), 4),
    ),
    DrawerItem(
      index: 5,
      icon: Icons.settings_rounded,
      title: 'الضبط والاعدادات',
      onTap: () => _navigateTo(context, const SettingsScreen(), 5),
    ),
    DrawerItem(
      index: 6,
      icon: Icons.info_outline_rounded,
      title: 'حول التطبيقات',
      onTap: () => _navigateTo(context, const ManageAboutAppScreen(), 6),
    ),
  ];
}

void _navigateTo(BuildContext context, Widget screen, int index) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

void _showLogoutDialog(
    BuildContext context, bool isDark, ColorScheme colorScheme) {
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
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'الغاء',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Cairo',
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            userProvider.clearUserData();
            Navigator.of(context).pushReplacementNamed(AppRoute.loginRouteName);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          child: const Text(
            'تسجيل الخروج',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildAppSidebar({
  required BuildContext context,
  required int selectedIndex,
  SidebarRole? role,
}) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final userProvider = Provider.of<UserProvider>(context);
  final isDark = themeProvider.isDark;
  final colorScheme = Theme.of(context).colorScheme;
  final currentUser = userProvider.currentUser;

  final userRole = role ??
      ((currentUser?.role == 'ADMIN' || currentUser?.role == 'MANAGER')
          ? SidebarRole.admin
          : SidebarRole.user);

  final items = userRole == SidebarRole.admin
      ? _buildAdminItems(context, selectedIndex)
      : _buildUserItems(context, selectedIndex);

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [colorScheme.surface, colorScheme.surface.withOpacity(0.95)]
            : [Colors.white, Colors.grey.shade50],
      ),
    ),
    child: Column(
      children: [
        DrawerHeaderWidget(
          isDark: isDark,
          colorScheme: colorScheme,
          displayName: currentUser?.displayName ?? 'User',
          username: currentUser?.username ?? '',
        ),
        Expanded(
          child: DrawerItemsList(
            items: items,
            selectedIndex: selectedIndex,
            isDark: isDark,
            colorScheme: colorScheme,
            isSidebar: true,
          ),
        ),
        DrawerLogoutSection(
          isDark: isDark,
          colorScheme: colorScheme,
          onLogout: () {
            _showLogoutDialog(context, isDark, colorScheme);
          },
        ),
      ],
    ),
  );
}
