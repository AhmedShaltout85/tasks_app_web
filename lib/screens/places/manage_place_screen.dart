import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
import 'package:tasks_app/common_widgets/responsive/empty_state_widget.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_form_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/common_widgets/responsive/top_nav_bar.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/controller/place_name_provider.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/services/connectivity_service.dart';

class ManagePlaceScreen extends StatefulWidget {
  const ManagePlaceScreen({super.key});

  @override
  State<ManagePlaceScreen> createState() => _ManagePlaceScreenState();
}

class _ManagePlaceScreenState extends State<ManagePlaceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ConnectivityService _connectivity = ConnectivityService();
  int _selectedDrawerIndex = 0;

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
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['selectedIndex'] != null) {
        setState(() {
          _selectedDrawerIndex = args['selectedIndex'] as int;
        });
      }
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
    await context.read<PlaceNameProvider>().fetchAllPlaceNames();
    _animationController.forward();
  }

  // void _showNoInternetDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('لا يوجد اتصال بالانترنت'),
  //       content: const Text(
  //         'يرجى التحقق من الاتصال والمحاولة مرة اخرى',
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
    final placeNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showResponsiveForm(
      context: context,
      title: 'اضافة مكان جديد',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: placeNameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفرع',
                hintText: 'ادخل اسم الفرع',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'فضلاً ادخل اسم الفرع';
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
                      await _addPlace(placeNameController.text.trim());
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

  Future<void> _addPlace(String placeName) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _addPlace(placeName),
      );
      return;
    }

    await context.read<PlaceNameProvider>().addPlaceName(placeName);

    if (mounted) {
      final provider = context.read<PlaceNameProvider>();
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
          message: 'فضلاً ادخل اسم الفرع',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );
        _fetchData();
      }
    }
  }

  void _showEditDialog(dynamic place) {
    final placeNameController = TextEditingController(text: place.placeName);
    final formKey = GlobalKey<FormState>();

    showResponsiveForm(
      context: context,
      title: 'تعديل اسم المكان',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: placeNameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفرع',
                hintText: 'ادخل اسم الفرع',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'فضلاً ادخل اسم الفرع';
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
                      await _updatePlace(
                        int.tryParse(place.id.toString()) ?? 0,
                        placeNameController.text.trim(),
                      );
                    }
                  },
                  child: const Text('تعديل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePlace(int id, String placeName) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _updatePlace(id, placeName),
      );
      return;
    }

    await context.read<PlaceNameProvider>().updatePlaceName(id, placeName);

    if (mounted) {
      final provider = context.read<PlaceNameProvider>();
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
          message: 'تم تعديل اسم الفرع بنجاح',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );
        _fetchData();
      }
    }
  }

  Future<void> _showDeleteConfirmation(dynamic place) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      ConnectionDialogService.showNoInternetDialog(
        context,
        // onRetry: () => _showDeleteConfirmation(place),
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
            Text('حذف المكان'),
          ],
        ),
        content: Text('هل تريد حذف الفرع "${place.placeName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final id = int.tryParse(place.id.toString());
      if (id != null) {
        await context.read<PlaceNameProvider>().deletePlaceName(id);
      }

      if (mounted) {
        final provider = context.read<PlaceNameProvider>();
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
            message: 'تم حذف الفرع بنجاح',
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
    final placeColor = Colors.teal;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.currentUser?.role == 'ADMIN' ||
        userProvider.currentUser?.role == 'MANAGER';
    final selectedIndex = _selectedDrawerIndex;

    return ResponsiveScaffold(
      topNavBar: buildRoleTopNavBar(context, selectedIndex),
      sidebarContent: buildAppSidebar(
        context: context,
        selectedIndex: selectedIndex,
      ),
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        actions: [
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
                  child: Icon(Icons.add_location, color: colorScheme.onPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveContentContainer(
        child: Consumer<PlaceNameProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.placeNames.isEmpty) {
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

            final places = provider.placeNames;

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
                            color: placeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.location_on, color: placeColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'الاماكن والفروع',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: placeColor,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: placeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${places.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: placeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: places.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.location_off,
                            title: 'لم يتم إضافة أي مكان او فرع حتى الآن',
                            action: ElevatedButton.icon(
                              onPressed: _showAddDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Place'),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: places.length,
                              itemBuilder: (context, index) {
                                final place = places[index];
                                return _buildPlaceCard(place, index, isDark,
                                    colorScheme, placeColor);
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

  Widget _buildPlaceCard(dynamic place, int index, bool isDark,
      ColorScheme colorScheme, Color placeColor) {
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
            backgroundColor: placeColor,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            place.placeName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Location',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(place),
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
                  onPressed: () => _showDeleteConfirmation(place),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
