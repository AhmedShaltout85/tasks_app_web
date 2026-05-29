import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/screens/login/login_screen.dart';
import 'package:tasks_app/screens/task/task_screen.dart';
import 'package:tasks_app/screens/task/user_task_screen.dart';
import 'package:tasks_app/screens/task/manager_task_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  bool _isAdminUser(String? role) {
    return role == 'ADMIN' || role == 'MANAGER';
  }

  bool _isManagerUser(String? role) {
    return role == 'GENERAL_MANAGER' || role == 'SECTOR_MANAGER';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final token = userProvider.token;

        // Only show loading on initial load (before we know if user has token or not)
        // Don't block UI when fetching additional data for TaskScreen
        if (userProvider.isInitializing) {
          log('AuthWrapper - isInitializing: true, showing loading');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If no token, show login screen (don't need to wait for anything)
        if (token == null || token.isEmpty) {
          log('AuthWrapper - No token, showing LoginScreen');
          return const LoginScreen();
        }

        // Token exists - user is logged in
        // Even if isUsersLoading is true, we should show the screen (not loading indicator)
        // because user is already authenticated
        final currentUser = userProvider.currentUser;
        final role = currentUser?.role;
        log('AuthWrapper - Token exists, role: $role, isUsersLoading: ${userProvider.isUsersLoading}');

        if (_isManagerUser(role)) {
          log('AuthWrapper - Manager user, showing ManagerTaskScreen');
          return const ManagerTaskScreen();
        } else if (_isAdminUser(role)) {
          log('AuthWrapper - Admin user, showing TaskScreen');
          return const TaskScreen();
        } else {
          log('AuthWrapper - Regular user, showing UserTaskScreen');
          return const UserTaskScreen();
        }
      },
    );
  }
}
