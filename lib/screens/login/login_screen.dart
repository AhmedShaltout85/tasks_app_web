import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_widgets.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/utils/app_route.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tasks_app/screens/signup/signup_screen.dart';
import 'package:tasks_app/services/connectivity_service.dart';
import 'package:tasks_app/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final ConnectivityService _connectivity = ConnectivityService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidInput(String username) {
    return username.trim().isNotEmpty;
  }

  Future<bool> _checkConnectivity() async {
    return await _connectivity.hasConnection();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ReusableToast.showToast(
        message: 'فضلا ادخل اسم المستخدم وكلمة المرور',
        bgColor: AppColors.redColor,
        textColor: AppColors.whiteColor,
        fontSize: 16,
      );
      return;
    }

    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      // Use the dialog service with retry option
      await ConnectionDialogService.showNoInternetDialog(
        context,
        onRetry: _handleLogin, // Retry the entire signup process
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.signIn(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (userProvider.error != null) {
        log(userProvider.error!);
        ReusableToast.showToast(
          message: userProvider.error!,
          bgColor: AppColors.redColor,
          textColor: AppColors.whiteColor,
          fontSize: 16,
        );
        userProvider.clearError();
      } else {
        ReusableToast.showToast(
          message: 'تم تسجيل الدخول بنجاح',
          bgColor: AppColors.greenColor,
          textColor: AppColors.whiteColor,
          fontSize: 16,
        );
        navigateToReplacementNamed(context, AppRoute.authWrapperRouteName);
      }
    } catch (e) {
      log('Login error: $e');
      if (!mounted) return;
      String errorMessage = 'إسم المستخدم او كلمة المرور غير صحيحة';
      if (e.toString().contains('401')) {
        errorMessage = 'إسم المستخدم او كلمة المرور غير صحيحة';
      } else if (e.toString().contains('connection')) {
        errorMessage = 'لا يوجد اتصال بالانترنت, يرجى التحقق من الاتصال';
      } else {
        errorMessage = 'حدث خطأ ما, يرجى المحاولة لاحقا';
      }
      ReusableToast.showToast(
        message: errorMessage,
        bgColor: AppColors.redColor,
        textColor: AppColors.whiteColor,
        fontSize: 16,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      ReusableToast.showToast(
        message: 'فضلا ادخل اسم المستخدم',
        bgColor: AppColors.redColor,
        textColor: AppColors.whiteColor,
        fontSize: 16,
      );
      return;
    }

    if (!_isValidInput(username)) {
      ReusableToast.showToast(
        message: 'اسم المستخدم غير صحيح',
        bgColor: AppColors.redColor,
        textColor: AppColors.whiteColor,
        fontSize: 16,
      );
      return;
    }

    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      _showNoInternetDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.forgotPassword(
        username: username,
        newPassword: '100100123',
      );

      ReusableToast.showToast(
        message: 'كلمة المرور الجديدة: 100100123',
        bgColor: AppColors.greenColor,
        textColor: AppColors.whiteColor,
        fontSize: 16,
      );
      if (!mounted) return;

      if (userProvider.error != null) {
        ReusableToast.showToast(
          message: userProvider.error!,
          bgColor: AppColors.redColor,
          textColor: AppColors.whiteColor,
          fontSize: 16,
        );
        userProvider.clearError();
      } else {
        ReusableToast.showToast(
          message: 'تم ارسال التعليمات بنجاح',
          bgColor: AppColors.greenColor,
          textColor: AppColors.whiteColor,
          fontSize: 16,
        );
      }
    } catch (e) {
      log('Forgot password error: $e');
      if (!mounted) return;
      ReusableToast.showToast(
        message: 'حدث خطأ ما, يرجى المحاولة لاحقا',
        bgColor: AppColors.redColor,
        textColor: AppColors.whiteColor,
        fontSize: 16,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لا يوجد اتصال بالانترنت'),
        content: const Text(
          'يرجى التحقق من الاتصال والمحاولة مرة اخرى',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 40,
                          top: -130,
                          child: Transform.rotate(
                            angle: -15,
                            child: Container(
                              height: 172,
                              width: 286,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 220,
                          top: -110,
                          child: Transform.rotate(
                            angle: -15,
                            child: Container(
                              height: 171,
                              width: 307,
                              decoration: BoxDecoration(
                                color: colorScheme.secondary,
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  gap(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.task_alt,
                      size: 60,
                      color: colorScheme.primary,
                    ),
                  ),
                  gap(height: 15),
                  Text(
                    'مرحبا بك مجددا',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  gap(height: 8),
                  Text(
                    'تسجيل الدخول للمتابعة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  gap(height: 25),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveValue(context,
                            defaultValue: 30.0,
                            conditionalValues: [
                          Condition.largerThan(name: TABLET, value: 40.0),
                        ]).value),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: isDark
                            ? Border.all(color: Colors.grey.shade800, width: 1)
                            : null,
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: TextField(
                        controller: _usernameController,
                        keyboardType: TextInputType.name,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'اسم المستخدم',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.person_2_outlined,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  gap(height: 15),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveValue(context,
                            defaultValue: 30.0,
                            conditionalValues: [
                          Condition.largerThan(name: TABLET, value: 40.0),
                        ]).value),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: isDark
                            ? Border.all(color: Colors.grey.shade800, width: 1)
                            : null,
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'كلمة المرور',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  gap(height: 3),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveValue(context,
                            defaultValue: 30.0,
                            conditionalValues: [
                          Condition.largerThan(name: TABLET, value: 40.0),
                        ]).value),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        child: Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  gap(height: 30),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveValue(context,
                            defaultValue: 30.0,
                            conditionalValues: [
                          Condition.largerThan(name: TABLET, value: 40.0),
                        ]).value),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor:
                                isDark ? colorScheme.onSurface : Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: isDark
                                        ? colorScheme.onSurface
                                        : Colors.white,
                                  ),
                                )
                              : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  gap(height: 30),
                  Text(
                    '- او تسجيل الدخول باستخدام -',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  gap(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(
                        icon: Icons.facebook,
                        color: const Color(0xFF1877F2),
                        isDark: isDark,
                        colorScheme: colorScheme,
                        onTap: () {
                          ReusableToast.showToast(
                            message: 'Facebook Sign In coming soon',
                            bgColor: AppColors.grayColor,
                            textColor: AppColors.whiteColor,
                            fontSize: 16,
                          );
                        },
                      ),
                      gap(width: 24),
                      _buildSocialButton(
                        icon: Icons.g_mobiledata,
                        color: const Color(0xFFDB4437),
                        isDark: isDark,
                        colorScheme: colorScheme,
                        onTap: () {
                          ReusableToast.showToast(
                            message: 'Google Sign In coming soon',
                            bgColor: AppColors.grayColor,
                            textColor: AppColors.whiteColor,
                            fontSize: 16,
                          );
                        },
                      ),
                      gap(width: 24),
                      _buildSocialButton(
                        icon: Icons.apple,
                        color: isDark ? Colors.white : Colors.black,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        onTap: () {
                          ReusableToast.showToast(
                            message: 'Apple Sign In coming soon',
                            bgColor: AppColors.grayColor,
                            textColor: AppColors.whiteColor,
                            fontSize: 16,
                          );
                        },
                      ),
                    ],
                  ),
                  gap(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ليس لديك حساب؟',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          navigateTo(context, const SignUpScreen());
                        },
                        child: Text(
                          ' إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  gap(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isDark
              ? Border.all(color: Colors.grey.shade800, width: 1)
              : Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(icon, size: 28, color: color),
      ),
    );
  }
}
