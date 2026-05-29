import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/common_widgets/responsive/drawer_items.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/screens/about_app/manage_about_app_screen.dart';
import 'package:tasks_app/screens/preventive/preventive_item_screen.dart';
import 'package:tasks_app/screens/preventive/manage_preventive_maintenance_screen.dart';
import 'package:tasks_app/screens/report/preventive_maintenance_report_screen.dart';
import 'package:tasks_app/screens/report/report_screen.dart';
import 'package:tasks_app/screens/settings/settings_screen.dart';

class CustomUserDrawer extends StatefulWidget {
  final int selectedIndex;
  final Function(int)? onIndexChanged;

  const CustomUserDrawer({
    super.key,
    this.selectedIndex = 1,
    this.onIndexChanged,
  });

  @override
  State<CustomUserDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomUserDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _selectedIndex;
  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToScreen(Widget screen, int index) {
    setState(() => _selectedIndex = index);
    widget.onIndexChanged?.call(index);
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = userProvider.currentUser;

    final items = [
      DrawerItem(
        index: 0,
        icon: Icons.shield_outlined,
        title: 'عناصر وقائية',
        onTap: () => _navigateToScreen(const PreventiveItemScreen(), 0),
      ),
      DrawerItem(
        index: 1,
        icon: Icons.assessment_rounded,
        title: 'التقارير اليومية',
        onTap: () => _navigateToScreen(const ReportScreen(), 1),
      ),
      DrawerItem(
        index: 2,
        icon: Icons.build_circle_outlined,
        title: 'تقارير صيانة وقائية',
        onTap: () =>
            _navigateToScreen(const PreventiveMaintenanceReportScreen(), 2),
      ),
      DrawerItem(
        index: 3,
        icon: Icons.add_circle_outline,
        title: 'إضافة صيانة وقائية',
        onTap: () =>
            _navigateToScreen(const ManagePreventiveMaintenanceScreen(), 3),
      ),
      DrawerItem(
        index: 4,
        icon: Icons.settings_rounded,
        title: 'الضبط والاعدادات',
        onTap: () => _navigateToScreen(const SettingsScreen(), 4),
      ),
      DrawerItem(
        index: 5,
        icon: Icons.info_outline_rounded,
        title: 'حول التطبيقات',
        onTap: () => _navigateToScreen(const ManageAboutAppScreen(), 5),
      ),
    ];

    return Drawer(
      child: Container(
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
              onHomeTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _animation,
                child: DrawerItemsList(
                  items: items,
                  selectedIndex: _selectedIndex,
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
              ),
            ),
            DrawerLogoutSection(
              isDark: isDark,
              colorScheme: colorScheme,
              onLogout: () {
                Navigator.pop(context);
                _showLogoutDialog(context, isDark, colorScheme);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext ctx,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: ctx,
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
              _userProvider.clearUserData();
              ReusableToast.showToast(
                message: 'تم تسجيل الخروج بنجاح',
                bgColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16,
              );
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
}
