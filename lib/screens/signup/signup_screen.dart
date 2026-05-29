import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_widgets.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/screens/auth/auth_wrapper.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/services/connectivity_service.dart';
import 'package:tasks_app/utils/app_colors.dart';
import 'package:tasks_app/utils/app_route.dart';
import 'package:responsive_framework/responsive_framework.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'USER';
  final ConnectivityService _connectivity = ConnectivityService();

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    if (_displayNameController.text.trim().isEmpty) {
      return 'فضلا ادخل الاسم المفضل';
    }
    if (_usernameController.text.trim().isEmpty) {
      return 'فضلا ادخل اسم المستخدم';
    }
    if (_passwordController.text.isEmpty) {
      return 'فضلا ادخل كلمة المرور';
    }
    if (_passwordController.text.length < 6) {
      return 'كلمة المرور يجب ان تكون على الاقل 6 حروف';
    }
    if (_confirmPasswordController.text.isEmpty) {
      return 'فضلا ادخل تاكيد كلمة المرور';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  Future<bool> _checkConnectivity() async {
    return await _connectivity.hasConnection();
  }

  Future<void> _handleSignup() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      ReusableToast.showToast(
        message: validationError,
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
        onRetry: _handleSignup, // Retry the entire signup process
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<UserProvider>().signUp(
            displayName: _displayNameController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
            role: '$_selectedRole',
            department: 'ادراة البرامج وصيانتها',
          );

      if (mounted) {
        final userProvider = context.read<UserProvider>();
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
            message: 'تم إنشاء حسابك بنجاح, يرجى تسجيل الدخول',
            bgColor: AppColors.greenColor,
            textColor: AppColors.whiteColor,
            fontSize: 16,
          );

          // Sign out immediately
          log('🚪 Signing out user...');
          await context.read<UserProvider>().signOut();
          log('✅ User signed out successfully');
          // Small delay for state propagation (like Firebase version)
          await Future.delayed(const Duration(milliseconds: 300));

          // Navigate to AuthWrapper instead of login
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      log('Signup error: $e');
      if (mounted) {
        ReusableToast.showToast(
          message: 'حدث خطأ ما, يرجى المحاولة لاحقا',
          bgColor: AppColors.redColor,
          textColor: AppColors.whiteColor,
          fontSize: 16,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = 14;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveValue(context,
                      defaultValue: 30.0,
                      conditionalValues: [
                        Condition.largerThan(name: TABLET, value: 40.0),
                      ]).value,
                  vertical: 10.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        size: 60,
                        color: colorScheme.primary,
                      ),
                    ),
                    gap(height: 24),
                    Text(
                      'هيا بنا نبدأ',
                      style: TextStyle(
                        fontSize: fontSize * 2,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    gap(height: 8),
                    Text(
                      'أنشاء حساب جديد, يرجى تعبئة الحقول التالية',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    gap(height: 35),
                    _buildThemedInputField(
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      controller: _displayNameController,
                      hintText: 'الاسم المفضل',
                      icon: Icons.badge_outlined,
                      isDark: isDark,
                      colorScheme: colorScheme,
                    ),
                    gap(height: 18),
                    _buildThemedInputField(
                      controller: _usernameController,
                      hintText: 'اسم المستخدم',
                      icon: Icons.person_outline,
                      isDark: isDark,
                      colorScheme: colorScheme,
                      keyboardType: TextInputType.name,
                    ),
                    gap(height: 18),
                    _buildThemedInputField(
                      controller: _passwordController,
                      hintText: 'كلمة المرور',
                      icon: Icons.lock_outline,
                      isDark: isDark,
                      colorScheme: colorScheme,
                      obscureText: _obscurePassword,
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
                    ),
                    gap(height: 18),
                    _buildThemedInputField(
                      controller: _confirmPasswordController,
                      hintText: 'تأكيد كلمة المرور',
                      icon: Icons.lock_outline,
                      isDark: isDark,
                      colorScheme: colorScheme,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    gap(height: 35),
                    SizedBox(
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
                          onPressed: _isLoading ? null : _handleSignup,
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
                              : Text(
                                  'إنشاء حساب جديد',
                                  style: TextStyle(
                                    fontSize: fontSize + 2,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    gap(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لدى حساب بالفعل؟ ',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.normal,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            navigateToReplacementNamed(
                              context,
                              AppRoute.loginRouteName,
                            );
                          },
                          child: Text(
                            'تسجيل دخول من هنا',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemedInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    required ColorScheme colorScheme,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            isDark ? Border.all(color: Colors.grey.shade800, width: 1) : null,
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
        textCapitalization: textCapitalization ?? TextCapitalization.none,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(icon, color: colorScheme.primary, size: 22),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
