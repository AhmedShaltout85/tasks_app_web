import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/responsive/empty_state_widget.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_form_container.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/controller/about_app_provider.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/models/recommended_item_model.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/services/connectivity_service.dart';

class AppRecommendedDetailsScreen extends StatefulWidget {
  final String appName;
  final int appId;
  final bool isAdmin;

  const AppRecommendedDetailsScreen({
    super.key,
    required this.appName,
    required this.appId,
    required this.isAdmin,
  });

  @override
  State<AppRecommendedDetailsScreen> createState() =>
      _AppRecommendedDetailsScreenState();
}

class _AppRecommendedDetailsScreenState
    extends State<AppRecommendedDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ConnectivityService _connectivity = ConnectivityService();
  List<RecommendedItem> _recommendedItems = [];

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
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
    final recommended = await context
        .read<AboutAppProvider>()
        .fetchAllRecommendedByAppName(widget.appName);
    setState(() {
      _recommendedItems = recommended;
    });
    _animationController.forward();
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
    final recommendedController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showResponsiveForm(
      context: context,
      title: 'اضافة تفصيل',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: recommendedController,
              decoration: const InputDecoration(
                labelText: 'التفاصيل',
                hintText: 'ادخل التفاصيل',
                prefixIcon: Icon(Icons.thumb_up_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'فضلا ادخل التفاصيل';
                }
                return null;
              },
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
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      await _addRecommended(recommendedController.text.trim());
                    }
                  },
                  child: const Text('اضافة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addRecommended(String recommendedValue) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _addRecommended(recommendedValue),
      );
      return;
    }

    await context
        .read<AboutAppProvider>()
        .addRecommended(widget.appName, recommendedValue);

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
          message: 'تم اضافة التفاصيل بنجاح',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );
        _fetchData();
      }
    }
  }

  void _showEditDialog(int index, RecommendedItem item) {
    final recommendedController =
        TextEditingController(text: item.recommendedValue);
    final formKey = GlobalKey<FormState>();

    showResponsiveForm(
      context: context,
      title: 'تعديل التفاصيل',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: recommendedController,
              decoration: const InputDecoration(
                labelText: 'التفاصيل',
                hintText: 'ادخل التفاصيل',
                prefixIcon: Icon(Icons.thumb_up_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'فضلا ادخل التفاصيل';
                }
                return null;
              },
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
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      await _updateRecommended(
                          index, item, recommendedController.text.trim());
                    }
                  },
                  child: const Text('تحديث'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRecommended(
      int index, RecommendedItem item, String newValue) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _updateRecommended(index, item, newValue),
      );
      return;
    }

    await context.read<AboutAppProvider>().deleteRecommended(item.id);
    if (!mounted) return;

    await context
        .read<AboutAppProvider>()
        .addRecommended(widget.appName, newValue);

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
          message: 'تم تحديث التفاصيل بنجاح',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );
        _fetchData();
      }
    }
  }

  Future<void> _showDeleteConfirmation(int index, RecommendedItem item) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _showDeleteConfirmation(index, item),
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
            Text('حذف التفاصيل'),
          ],
        ),
        content: Text('هل أنت متاكد من حذف "${item.recommendedValue}"؟'),
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
      await context.read<AboutAppProvider>().deleteRecommended(item.id);

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
            message: 'تم حذف التفاصيل بنجاح',
            bgColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16,
          );
          _fetchData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;
    final appColor = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appName),
        actions: [
          // Only show add button if user is admin
          if (widget.isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showAddDialog,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.add,
                      color: isDark ? Colors.black87 : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ResponsiveContentContainer(
        child: Consumer<AboutAppProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && _recommendedItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'تحميل...',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

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
                          child: Icon(Icons.thumb_up, color: appColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'التفاصيل',
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
                            '${_recommendedItems.length}',
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
                    child: _recommendedItems.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.thumb_up_outlined,
                            title: 'لا يوجد تفاصيل',
                            action: widget.isAdmin
                                ? ElevatedButton.icon(
                                    onPressed: _showAddDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('اضافة تفاصيل'),
                                  )
                                : null,
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _recommendedItems.length,
                              itemBuilder: (context, index) {
                                final item = _recommendedItems[index];
                                return _buildRecommendedCard(
                                  item,
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

  Widget _buildRecommendedCard(
    RecommendedItem item,
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
            item.recommendedValue,
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
                'تفصيل',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          // Only show edit/delete buttons if user is admin
          trailing: widget.isAdmin
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(index, item),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(index, item),
                      ),
                    ),
                  ],
                )
              : null, // No trailing buttons for regular users
        ),
      ),
    );
  }
}
