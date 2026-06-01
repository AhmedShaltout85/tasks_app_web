import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
import 'package:tasks_app/common_widgets/responsive/empty_state_widget.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_form_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/controller/about_app_provider.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/models/about_app_model.dart';
import 'package:tasks_app/screens/about_app/app_recommended_details_screen.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/services/connectivity_service.dart';

class ManageAboutAppScreen extends StatefulWidget {
  const ManageAboutAppScreen({super.key});

  @override
  State<ManageAboutAppScreen> createState() => _ManageAboutAppScreenState();
}

class _ManageAboutAppScreenState extends State<ManageAboutAppScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ConnectivityService _connectivity = ConnectivityService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      // Schedule after the current build phase to avoid notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkUserStatus();
          _fetchData();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        onRetry: _fetchData,
      );
      return;
    }
    await context.read<AboutAppProvider>().fetchAllAboutApps();
    if (mounted) {
      _animationController.forward();
    }
  }

  // Check user status - ADMINS/MANAGERS can edit, USERS can only view
  void _checkUserStatus() {
    final userProvider = context.read<UserProvider>();
    final role = userProvider.currentUser?.role;
    context.read<AboutAppProvider>().setUserRole(
          role,
          shouldNotify: false,
        );
  }

  // void _showNoInternetDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('لا يوجد اتصال بالانترنت'),
  //       content: const Text(
  //         'يرجى التحقق من الاتصال والمحاولة مرة اخرى.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('حسنا'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showAddDialog() {
    final appNameController = TextEditingController();
    final recommendedController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showResponsiveForm(
      context: context,
      title: 'ادارة التطبيقات والاجهزة',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: appNameController,
              decoration: const InputDecoration(
                labelText: 'اسم التطبيق/الجهاز',
                hintText: 'ادخل اسم التطبيق/الجهاز',
                prefixIcon: Icon(Icons.apps),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'فضلا ادخل اسم التطبيق/الجهاز';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: recommendedController,
              decoration: const InputDecoration(
                labelText: 'تفاصيل التطبيق/الجهاز',
                hintText: 'ادخل تفاصيل التطبيق/الجهاز',
                prefixIcon: Icon(Icons.thumb_up_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('الغاء'),
                ),
                const SizedBox(width: 8),
                Consumer<AboutAppProvider>(
                  builder: (context, provider, child) {
                    return provider.isAdmin
                        ? ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                final recommended =
                                    recommendedController.text.trim();
                                await _addAboutApp(
                                  appNameController.text.trim(),
                                  recommended.isNotEmpty ? [recommended] : [],
                                );
                              }
                            },
                            child: const Text('اضافة'),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAboutApp(String appName, List<String> recommended) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _addAboutApp(appName, recommended),
      );
      return;
    }

    final provider = context.read<UserProvider>();
    final department = provider.currentUser?.department;

    if (department == null) {
      ReusableToast.showToast(
        message: 'لم يتم العثور على القسم',
        bgColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16,
      );
      return;
    }

    await context
        .read<AboutAppProvider>()
        .addAboutApp(appName, department, recommended);

    if (mounted) {
      final aboutProvider = context.read<AboutAppProvider>();
      if (aboutProvider.error != null) {
        ReusableToast.showToast(
          message: aboutProvider.error!,
          bgColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16,
        );
        aboutProvider.clearError();
      } else {
        ReusableToast.showToast(
          message: 'تم اضافة التطبيق بنجاح',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );
        await _fetchData();
      }
    }
  }

  void _showEditDialog(AboutApp aboutApp) {
    final appNameController = TextEditingController(text: aboutApp.appName);
    final recommendedText = (aboutApp.recommended as List).join(', ');
    final recommendedController = TextEditingController(text: recommendedText);
    final formKey = GlobalKey<FormState>();

    showResponsiveForm(
      context: context,
      title: 'تعديل التطبيقات والاجهزة',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: appNameController,
              decoration: const InputDecoration(
                labelText: 'اسم التطبيق/الجهاز',
                hintText: 'ادخل اسم التطبيق/الجهاز',
                prefixIcon: Icon(Icons.apps),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'فضلا ادخل اسم التطبيق/الجهاز';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: recommendedController,
              decoration: const InputDecoration(
                labelText: 'تفاصيل التطبيق/الجهاز (اختيارى)',
                hintText: 'ادخل القيم الموصى بها (مفصولة بفواصل)',
                prefixIcon: Icon(Icons.thumb_up_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('الغاء'),
                ),
                const SizedBox(width: 8),
                Consumer<AboutAppProvider>(
                  builder: (context, provider, child) {
                    return provider.isAdmin
                        ? ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                final recommended =
                                    recommendedController.text.trim();
                                final recommendedList = recommended.isNotEmpty
                                    ? recommended
                                        .split(',')
                                        .map((e) => e.trim())
                                        .toList()
                                    : <String>[];
                                await _updateAboutApp(
                                  aboutApp.id!,
                                  appNameController.text.trim(),
                                  recommendedList,
                                );
                              }
                            },
                            child: const Text('تحديث'),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAboutApp(
      int id, String appName, List<String> recommended) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _updateAboutApp(id, appName, recommended),
      );
      return;
    }

    final provider = context.read<UserProvider>();
    final department = provider.currentUser?.department;

    if (department == null) {
      ReusableToast.showToast(
        message: 'لم يتم العثور على القسم',
        bgColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16,
      );
      return;
    }

    await context
        .read<AboutAppProvider>()
        .updateAboutApp(id, appName, department, recommended);

    if (mounted) {
      final aboutProvider = context.read<AboutAppProvider>();
      if (aboutProvider.error != null) {
        ReusableToast.showToast(
          message: aboutProvider.error!,
          bgColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16,
        );
        aboutProvider.clearError();
      } else {
        ReusableToast.showToast(
          message: 'تم تحديث التطبيق بنجاح',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );
        await _fetchData();
      }
    }
  }

  Future<void> _showDeleteConfirmation(AboutApp aboutApp) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _showDeleteConfirmation(aboutApp),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('حذف التطبيق/الجهاز'),
          ],
        ),
        content:
            Text('هل أنت متاكد من حذف التطبيق/الجهاز "${aboutApp.appName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('الغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<AboutAppProvider>().deleteAboutApp(aboutApp.id!);

      if (mounted) {
        final provider = context.read<AboutAppProvider>();
        if (provider.error != null) {
          ReusableToast.showToast(
            message: provider.error!,
            bgColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16,
          );
          provider.clearError();
        } else {
          ReusableToast.showToast(
            message: 'تم حذف التطبيق/الجهاز بنجاح',
            bgColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16,
          );
          await _fetchData();
        }
      }
    }
  }

  Map<String, List<AboutApp>> _groupByAppName(List<AboutApp> aboutApps) {
    final Map<String, List<AboutApp>> grouped = {};
    for (var app in aboutApps) {
      if (grouped.containsKey(app.appName)) {
        grouped[app.appName]!.add(app);
      } else {
        grouped[app.appName] = [app];
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;
    final appColor = Colors.blue;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.currentUser?.role == 'ADMIN' ||
        userProvider.currentUser?.role == 'MANAGER';
    final selectedIndex = isAdmin ? 3 : 6;

    return ResponsiveScaffold(
      sidebarContent: buildAppSidebar(
        context: context,
        selectedIndex: selectedIndex,
      ),
      appBar: AppBar(
        // title: const Text('ادارة التطبيقات والاجهزة'),
        backgroundColor: Colors.transparent,
        actions: [
          Consumer<AboutAppProvider>(
            builder: (context, provider, child) {
              return provider.isAdmin
                  ? Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _showAddDialog,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child:
                                Icon(Icons.add, color: colorScheme.onPrimary),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: ResponsiveContentContainer(
        child: Consumer<AboutAppProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.aboutApps.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'تحميل',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            final groupedApps = _groupByAppName(provider.aboutApps);
            final appNames = groupedApps.keys.toList();

            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: appColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.info_outline, color: appColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'التطبيقات والاجهزة',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: appColor,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: appColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${appNames.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: appColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: appNames.isEmpty
                        ? Consumer<AboutAppProvider>(
                            builder: (context, provider, child) {
                              return EmptyStateWidget(
                                icon: Icons.info_outline,
                                title: 'لا يوجد تطبيقات/اجهزة',
                                action: provider.isAdmin
                                    ? ElevatedButton.icon(
                                        onPressed: _showAddDialog,
                                        icon: const Icon(Icons.add),
                                        label: const Text('اضافة تطبيق/اجهزة'),
                                      )
                                    : null,
                              );
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: appNames.length,
                              itemBuilder: (context, index) {
                                final appName = appNames[index];
                                final apps = groupedApps[appName]!;
                                return _buildAppCard(
                                  appName,
                                  apps,
                                  index,
                                  isDark,
                                  colorScheme,
                                  appColor,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppCard(
    String appName,
    List<AboutApp> apps,
    int index,
    bool isDark,
    ColorScheme colorScheme,
    Color appColor,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isDark ? Border.all(color: Colors.grey.shade800) : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: appColor,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            appName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.thumb_up_outlined,
                size: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${apps.length} تفصيل',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: Consumer<AboutAppProvider>(
            builder: (context, provider, child) {
              // Only show edit/delete buttons for admins
              if (!provider.isAdmin) return const SizedBox.shrink();

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        if (apps.isNotEmpty) {
                          _showEditDialog(apps.first);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        if (apps.isNotEmpty) {
                          _showDeleteConfirmation(apps.first);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          onTap: () async {
            if (apps.isNotEmpty) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Consumer<AboutAppProvider>(
                    builder: (context, provider, child) {
                      return AppRecommendedDetailsScreen(
                        appName: appName,
                        appId: apps.first.id!,
                        isAdmin: provider.isAdmin, // Pass admin status
                      );
                    },
                  ),
                ),
              );
              await _fetchData();
            }
          },
        ),
      ),
    );
  }
}
