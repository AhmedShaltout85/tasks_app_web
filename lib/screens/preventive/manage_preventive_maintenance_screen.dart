import 'package:flutter/material.dart';
import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/common_widgets/responsive/top_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/controller/preventive_provider.dart';
import 'package:tasks_app/controller/about_app_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/controller/place_name_provider.dart';
import 'package:tasks_app/models/preventive_item_model.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/services/connectivity_service.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';

class ManagePreventiveMaintenanceScreen extends StatefulWidget {
  const ManagePreventiveMaintenanceScreen({super.key});

  @override
  State<ManagePreventiveMaintenanceScreen> createState() =>
      _ManagePreventiveMaintenanceScreenState();
}

class _ManagePreventiveMaintenanceScreenState
    extends State<ManagePreventiveMaintenanceScreen> {
  final ConnectivityService _connectivity = ConnectivityService();
  String? selectedPlaceName;
  String? selectedAppName;
  String? selectedAction;
  List<PreventiveItemModel> _actions = [];
  bool _isLoading = false;
  bool _isRemote = false;
  final TextEditingController _subPlaceController =
      TextEditingController(text: 'لايوجد');
  int _selectedDrawerIndex = 5;

  @override
  void initState() {
    super.initState();
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
    _subPlaceController.dispose();
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

    final userProvider = context.read<UserProvider>();
    final department = userProvider.currentUser?.department ?? '';

    await context.read<PlaceNameProvider>().fetchPlaceNameStrings();
    // await context.read<AboutAppProvider>().fetchAppsByDepartment(department);
    // await context
    //     .read<PreventiveProvider>()
    //     .fetchAllPreventiveItemsByDepartment(department);
  }

  void _onPlaceSelected(String? placeName) {
    setState(() {
      selectedPlaceName = placeName;
    });
  }

  void _onAppSelected(String? appName) {
    setState(() {
      selectedAppName = appName;
      selectedAction = null;
      _actions = [];
    });
    if (appName != null && appName != 'الكل') {
      _loadActionItems(appName);
    }
  }

  Future<void> _loadActionItems(String appName) async {
    setState(() => _isLoading = true);
    try {
      await context
          .read<PreventiveProvider>()
          .fetchPreventiveItemByAppName(appName);
      final items = context.read<PreventiveProvider>().preventiveItems;
      setState(() {
        _actions = items;
      });
    } catch (e) {
      ReusableToast.showToast(
        message: 'Error loading actions: $e',
        bgColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onActionSelected(PreventiveItemModel action) {
    setState(() {
      selectedAction = action.action;
    });
  }

  Future<void> _addMaintenance() async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      // Create a wrapper function

      await ConnectionDialogService.showNoInternetDialog(
        context,
      );
      return;
    }
    if (selectedPlaceName == null || selectedPlaceName == 'الكل') {
      ReusableToast.showToast(
        message: 'الرجاء اختيار مكان الزيارة',
        bgColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 14,
      );
      return;
    }

    if (selectedAppName == null || selectedAppName == 'الكل') {
      ReusableToast.showToast(
        message: 'الرجاء اختيار اسم التطبيق',
        bgColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 14,
      );
      return;
    }

    if (selectedAction == null) {
      ReusableToast.showToast(
        message: 'الرجاء اختيار العمل',
        bgColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 14,
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final username = userProvider.currentUser?.username ?? 'admin';
    final department = userProvider.currentUser?.department ?? 'IT';

    final subPlace = _subPlaceController.text.trim().isEmpty
        ? 'لايوجد'
        : _subPlaceController.text.trim();

    setState(() => _isLoading = true);
    try {
      await context.read<PreventiveProvider>().addPreventiveMaintenance(
            appName: selectedAppName!,
            action: selectedAction!,
            username: username,
            placeName: selectedPlaceName!,
            subPlace: subPlace,
            isRemote: _isRemote,
            department: department,
          );

      ReusableToast.showToast(
        message: 'تمت إضافة الصيانة الوقائية بنجاح',
        bgColor: Colors.green,
        textColor: Colors.white,
        fontSize: 14,
      );

      setState(() {
        selectedAction = null;
      });
    } catch (e) {
      ReusableToast.showToast(
        message: 'Error: $e',
        bgColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text(label),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          IconButton(
            icon: Icon(Icons.add, color: colorScheme.onSurface),
            onPressed: _addMaintenance,
          ),
        ],
      ),
      body: ResponsiveContentContainer(
        child: Consumer4<PlaceNameProvider, AboutAppProvider, UserProvider,
            PreventiveProvider>(
          builder: (context, placeProvider, aboutAppProvider, userProvider,
              preventiveProvider, child) {
            final placeNames = placeProvider.placeNameStrings;
            final appNames =
                aboutAppProvider.aboutApps.map((a) => a.appName).toList();

            final placeList = ['الكل', ...placeNames];
            final appList = ['الكل', ...appNames];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'مكان الزيارة',
                          value: selectedPlaceName ?? 'الكل',
                          items: placeList,
                          icon: Icons.location_on,
                          onChanged: (value) {
                            if (value != null && value != 'الكل') {
                              _onPlaceSelected(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: 'اسم التطبيق',
                          value: selectedAppName ?? 'الكل',
                          items: appList,
                          icon: Icons.apps,
                          onChanged: (value) {
                            if (value != null && value != 'الكل') {
                              _onAppSelected(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'اختر العمل:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row with isRemote toggle and subPlace textfield
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // isRemote toggle
                      Flexible(
                        flex: 1,
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: 80, // Set minimum width
                            maxWidth: 120, // Set maximum width
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isRemote
                                ? Colors.blue.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isRemote
                                  ? Colors.blue.shade300
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                _isRemote ? Icons.home_work : Icons.home,
                                color: _isRemote
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade600,
                                size: 18,
                              ),
                              Switch(
                                value: _isRemote,
                                onChanged: (value) {
                                  setState(() {
                                    _isRemote = value;
                                  });
                                },
                                activeColor: Colors.blue.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // subPlace textfield
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _subPlaceController,
                          decoration: InputDecoration(
                            labelText: 'المكان الفرعى',
                            hintText: 'لايوجد',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_actions.isEmpty && selectedAppName != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'لا توجد أعمال لهذا التطبيق',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _actions.map((action) {
                        final isSelected = selectedAction == action.action;
                        return GestureDetector(
                          onTap: () => _onActionSelected(action),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              action.action,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  if (selectedAction != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تم اختيار:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  selectedAction!,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _addMaintenance,
                            child: const Text(
                              'إضافة',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
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
}
