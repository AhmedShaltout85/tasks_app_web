import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tasks_app/controller/complaint_provider.dart';

import 'package:tasks_app/controller/local_control/cache_helper.dart';
import 'package:tasks_app/controller/preventive_provider.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/controller/place_name_provider.dart';
import 'package:tasks_app/controller/daily_task_provider.dart';
import 'package:tasks_app/controller/about_app_provider.dart';
import 'package:tasks_app/screens/about_app/manage_about_app_screen.dart';
import 'package:tasks_app/screens/auth/auth_wrapper.dart';
import 'package:tasks_app/screens/complaints/manage_complmaints_screen.dart';
import 'package:tasks_app/screens/login/login_screen.dart';
import 'package:tasks_app/screens/places/manage_place_screen.dart';
import 'package:tasks_app/screens/preventive/preventive_item_screen.dart';
import 'package:tasks_app/screens/preventive/manage_preventive_maintenance_screen.dart';
import 'package:tasks_app/screens/report/report_screen.dart';
import 'package:tasks_app/screens/user/manage_user_screen.dart';
import 'package:tasks_app/screens/user/manage_users.dart';
import 'package:tasks_app/screens/signup/signup_screen.dart';
import 'package:tasks_app/screens/splash/splash_screen.dart';
import 'package:tasks_app/screens/task/task_screen.dart';
import 'package:tasks_app/screens/task/user_task_screen.dart';

import 'package:tasks_app/utils/app_route.dart';
import 'package:tasks_app/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PlaceNameProvider()),
        ChangeNotifierProvider(create: (_) => DailyTaskProvider()),
        ChangeNotifierProvider(create: (_) => AboutAppProvider()),
        ChangeNotifierProvider(create: (_) => PreventiveProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ResponsiveBreakpoints.builder(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'تطبيق المهام اليومية',
              theme: themeProvider.themeMode == ThemeMode.dark
                  ? AppTheme.darkTheme
                  : AppTheme.lightTheme,
              home: const SplashScreen(),
              routes: {
                AppRoute.loginRouteName: (context) => const LoginScreen(),
                AppRoute.signupRouteName: (context) => const SignUpScreen(),
                AppRoute.taskRouteName: (context) => const TaskScreen(),
                AppRoute.userTaskRouteName: (context) => const UserTaskScreen(),
                AppRoute.authWrapperRouteName: (context) => const AuthWrapper(),
                AppRoute.reportRouteName: (context) => const ReportScreen(),
                AppRoute.manageUsersRouteName: (context) =>
                    const ManageUsersScreen(),
                AppRoute.manageUserRouteName: (context) =>
                    const ManageUserScreen(),
                AppRoute.managePlaceRouteName: (context) =>
                    const ManagePlaceScreen(),
                AppRoute.manageAboutAppRouteName: (context) =>
                    const ManageAboutAppScreen(),
                AppRoute.preventiveItemRouteName: (context) =>
                    const PreventiveItemScreen(),
                AppRoute.preventiveMaintenanceRouteName: (context) =>
                    const ManagePreventiveMaintenanceScreen(),
                AppRoute.complaintsRouteName: (context) =>
                    const ManageComplaintsScreen(),
              },
            ),
            breakpoints: [
              const Breakpoint(start: 0, end: 600, name: MOBILE),
              const Breakpoint(start: 600, end: 1024, name: TABLET),
              const Breakpoint(
                  start: 1024, end: double.infinity, name: DESKTOP),
            ],
          ),
        );
      },
    );
  }
}
