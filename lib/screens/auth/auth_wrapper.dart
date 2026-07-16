import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/screens/login/login_screen.dart';
import 'package:tasks_app/screens/task/task_screen.dart';
import 'package:tasks_app/screens/task/user_task_screen.dart';
import 'package:tasks_app/screens/task/manager_task_screen.dart';
import 'package:tasks_app/utils/auth_status.dart';

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

        if (userProvider.isInitializing) {
          log('AuthWrapper - isInitializing: true, showing loading');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (token == null || token.isEmpty) {
          log('AuthWrapper - No token, showing LoginScreen');
          return const LoginScreen();
        }

        final currentUser = userProvider.currentUser;
        final role = currentUser?.role;
        log('AuthWrapper - Token exists, role: $role, isUsersLoading: ${userProvider.isUsersLoading}');

        Widget screen;
        if (_isManagerUser(role)) {
          log('AuthWrapper - Manager user, showing ManagerTaskScreen');
          screen = const ManagerTaskScreen();
        } else if (_isAdminUser(role)) {
          log('AuthWrapper - Admin user, showing TaskScreen');
          screen = const TaskScreen();
        } else {
          log('AuthWrapper - Regular user, showing UserTaskScreen');
          screen = const UserTaskScreen();
        }

        if (userProvider.authStatus == AuthStatus.refreshing) {
          return Stack(
            children: [
              screen,
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    color: Colors.black87,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Refreshing session...',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return screen;
      },
    );
  }
}
