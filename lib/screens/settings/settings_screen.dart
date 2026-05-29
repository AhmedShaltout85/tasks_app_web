import 'package:flutter/material.dart';
import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_form_container.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/services/connectivity_service.dart';
import 'package:tasks_app/utils/app_route.dart';

class SettingsScreen extends StatefulWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ConnectivityService _connectivity = ConnectivityService();

  Future<bool> _checkConnectivity() async {
    return await _connectivity.hasConnection();
  }

  void _showChangePasswordDialog(bool isDark, ColorScheme colorScheme) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    bool isLoading = false;

    showResponsiveForm(
      context: context,
      title: 'تغيير كلمة المرور',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: !showCurrentPassword,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  labelStyle: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  hintText: 'ادخل كلمة المرور الحالية',
                  hintStyle: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Cairo',
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () {
                      setDialogState(() {
                        showCurrentPassword = !showCurrentPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'فضلاً ادخل كلمة المرور الحالية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                strutStyle: StrutStyle(fontFamily: 'Cairo'),
                controller: newPasswordController,
                obscureText: !showNewPassword,
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  labelStyle: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  hintText: 'ادخل كلمة المرور الجديدة',
                  hintStyle: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () {
                      setDialogState(() {
                        showNewPassword = !showNewPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'فضلاً ادخل كلمة المرور الجديدة';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون على الأقل 6 حروف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                strutStyle: StrutStyle(fontFamily: 'Cairo'),
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  labelStyle: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  hintText: 'تأكيد كلمة المرور مرة أخرى',
                  hintStyle: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () {
                      setDialogState(() {
                        showConfirmPassword = !showConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'فضلاً اكد كلمة المرور الجديدة';
                  }
                  if (value != newPasswordController.text) {
                    return 'كلمة المرور غير متطابقة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                final hasConnection =
                                    await _checkConnectivity();
                                if (!hasConnection) {
                                  ConnectionDialogService.showNoInternetDialog(
                                    context,
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isLoading = true;
                                });

                                try {
                                  final userProvider =
                                      Provider.of<UserProvider>(
                                    context,
                                    listen: false,
                                  );

                                  await userProvider.changePassword(
                                    currentPassword:
                                        currentPasswordController.text,
                                    newPassword: newPasswordController.text,
                                  );

                                  if (!context.mounted) return;

                                  if (userProvider.error != null) {
                                    ReusableToast.showToast(
                                      message: userProvider.error!,
                                      bgColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 16,
                                    );
                                    userProvider.clearError();
                                  } else {
                                    Navigator.pop(context);
                                    ReusableToast.showToast(
                                      message: 'تم تغيير كلمة المرور بنجاح',
                                      bgColor: Colors.green,
                                      textColor: Colors.white,
                                      fontSize: 16,
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ReusableToast.showToast(
                                    message:
                                        'حدث خطأ اثناء تغيير كلمة المرور, يرجى المحاولة مرة أخرى',
                                    bgColor: Colors.red,
                                    textColor: Colors.white,
                                    fontSize: 16,
                                  );
                                } finally {
                                  if (context.mounted) {
                                    setDialogState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'تغيير كلمة المرور',
                              style: TextStyle(fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<UserProvider>().currentUser;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.currentUser?.role == 'ADMIN' ||
        userProvider.currentUser?.role == 'MANAGER';
    final selectedIndex = isAdmin ? 7 : 5;

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
      ),
      body: ResponsiveContentContainer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'الحساب الشخصي',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primaryContainer, colorScheme.primary],
                ),
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? Border.all(color: Colors.grey.shade800, width: 1)
                    : null,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: colorScheme.onPrimary,
                        child: Text(
                          '${user?.displayName.substring(0, 1).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user?.displayName}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.department ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onPrimary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'الحماية',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lock_reset, color: colorScheme.primary),
                ),
                title: Text(
                  'تغيير كلمة المرور',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'تغيير كلمة المرور الخاصة بك',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                onTap: () => _showChangePasswordDialog(isDark, colorScheme),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'المظهر',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: colorScheme.primary,
                  ),
                ),
                title: Text(
                  'الوضع الداكن',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isDark ? 'تفعيل الوضع الداكن' : 'تفعيل الوضع الفاتح',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                value: isDark,
                activeThumbColor: colorScheme.primary,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.logout, color: colorScheme.error),
                ),
                title: Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'الخروج من حسابك',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.error.withOpacity(0.7),
                ),
                onTap: () => _showLogoutDialog(context, isDark, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
      BuildContext ctx, bool isDark, ColorScheme colorScheme) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متاكد أنك تريد تسجيل الخروج؟',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface.withOpacity(0.8),
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
                color: colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Get the UserProvider instance
              final userProvider =
                  Provider.of<UserProvider>(ctx, listen: false);

              // Call clearUserData method (you need to implement this in your UserProvider)
              userProvider.clearUserData();

              ReusableToast.showToast(
                message: 'تم تسجيل الخروج بنجاح',
                bgColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16,
              );

              // Navigate to login screen or pop until login
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoute.loginRouteName, (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
