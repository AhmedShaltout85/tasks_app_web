// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
// import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
// import 'package:tasks_app/common_widgets/responsive/responsive_form_container.dart';
// import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
// import 'package:tasks_app/common_widgets/responsive/top_nav_bar.dart';
// import 'package:tasks_app/controller/preventive_provider.dart';
// import 'package:tasks_app/controller/about_app_provider.dart';
// import 'package:tasks_app/controller/user_provider.dart';
// import 'package:tasks_app/models/preventive_item_model.dart';
// import 'package:tasks_app/services/connection_dialog_service.dart';
// import 'package:tasks_app/services/connectivity_service.dart';
// import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';

// class PreventiveItemScreen extends StatefulWidget {
//   const PreventiveItemScreen({super.key});

//   @override
//   State<PreventiveItemScreen> createState() => _PreventiveItemScreenState();
// }

// class _PreventiveItemScreenState extends State<PreventiveItemScreen> {
//   final ConnectivityService _connectivity = ConnectivityService();
//   final TextEditingController _actionController = TextEditingController();
//   final ScrollController _horizontalScrollController = ScrollController();
//   bool _isLoading = false;
//   String? _selectedAppName;
//   int _selectedDrawerIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // Read selected index from route arguments
//       final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//       if (args != null && args['selectedIndex'] != null) {
//         setState(() {
//           _selectedDrawerIndex = args['selectedIndex'] as int;
//         });
//       }
//       _checkUserStatus();
//       _fetchData();
//     });
//   }

//   @override
//   void dispose() {
//     _actionController.dispose();
//     _horizontalScrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchData() async {
//     final hasConnection = await _connectivity.hasConnection();
//     if (!hasConnection) {
//       ConnectionDialogService.showNoInternetDialog(
//         context,
//         onRetry: _fetchData,
//       );
//       return;
//     }

//     final userProvider = context.read<UserProvider>();
//     final department = userProvider.currentUser?.department;

//     if (department != null && department.isNotEmpty) {
//       await context.read<AboutAppProvider>().fetchAppsByDepartment(department);
//       await context
//           .read<PreventiveProvider>()
//           .fetchAllPreventiveItemsByDepartment(department);

//       // If no results, try default department
//       final provider = context.read<PreventiveProvider>();
//       if (provider.preventiveItems.isEmpty) {
//         await context
//             .read<PreventiveProvider>()
//             .fetchAllPreventiveItemsByDepartment('IT');
//       }
//     } else {
//       await context.read<AboutAppProvider>().fetchAllAboutApps();
//     }
//   }

//   // Check user status - ADMINS/MANAGERS can edit, USERS can only view
//   void _checkUserStatus() {
//     final userProvider = context.read<UserProvider>();
//     final role = userProvider.currentUser?.role;
//     context.read<AboutAppProvider>().setUserRole(
//           role,
//           shouldNotify: false,
//         );
//   }

//   // void _showNoInternetDialog() {
//   //   showDialog(
//   //     context: context,
//   //     builder: (context) => AlertDialog(
//   //       title: const Text('لا يوجد اتصال بالانترنت'),
//   //       content: const Text('يرجى التحقق من الاتصال والمحاولة مرة اخرى'),
//   //       actions: [
//   //         TextButton(
//   //           onPressed: () => Navigator.pop(context),
//   //           child: const Text('حسنا'),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

//   List<PreventiveItemModel> _getItemsForApp(String appName) {
//     final provider = context.read<PreventiveProvider>();
//     return provider.preventiveItems
//         .where((item) => item.appName == appName)
//         .toList();
//   }

//   void _showAddEditDialog(
//       {PreventiveItemModel? item, required String appName}) async {
//     if (item != null) {
//       _actionController.text = item.action;
//     } else {
//       _actionController.clear();
//     }

//     showResponsiveForm(
//       context: context,
//       title: item == null ? 'إضافة حدث $appName' : 'تحديث حدث $appName',
//       content: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           TextField(
//             controller: _actionController,
//             decoration: InputDecoration(
//               labelText: 'الحدث',
//               hintText: 'فضلا ادخل الحدث',
//               prefixIcon: const Icon(Icons.build),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () => _saveItem(item, appName),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: Text(item == null ? 'اضافة' : 'تحديث'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _saveItem(PreventiveItemModel? item, String appName) async {
//     final hasConnection = await _connectivity.hasConnection();
//     if (!hasConnection) {
//       // Create a wrapper function

//       await ConnectionDialogService.showNoInternetDialog(
//         context,
//       );
//       return;
//     }
//     if (_actionController.text.isEmpty) {
//       ReusableToast.showToast(
//         message: 'يرجى ادخال الحدث',
//         bgColor: Colors.orange,
//         textColor: Colors.white,
//         fontSize: 14,
//       );
//       return;
//     }

//     Navigator.pop(context);
//     setState(() => _isLoading = true);

//     final userProvider = context.read<UserProvider>();
//     final department = userProvider.currentUser?.department ?? 'IT';

//     try {
//       final provider = context.read<PreventiveProvider>();
//       if (item == null) {
//         await provider.addPreventiveItem(
//             appName, _actionController.text, department);
//         ReusableToast.showToast(
//           message: 'تم اضافة الحدث بنجاح',
//           bgColor: Colors.green,
//           textColor: Colors.white,
//           fontSize: 14,
//         );
//       } else {
//         await provider.updatePreventiveItem(
//             item.id!, appName, _actionController.text, department);
//         ReusableToast.showToast(
//           message: 'تم تحديث الحدث بنجاح',
//           bgColor: Colors.green,
//           textColor: Colors.white,
//           fontSize: 14,
//         );
//       }
//     } catch (e) {
//       ReusableToast.showToast(
//         message: 'Error: $e',
//         bgColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 14,
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _deleteItem(PreventiveItemModel item) async {
//     final hasConnection = await _connectivity.hasConnection();
//     if (!hasConnection) {
//       // Create a wrapper function

//       await ConnectionDialogService.showNoInternetDialog(
//         context,
//       );
//       return;
//     }
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('حذف حدث'),
//         content: Text('هل تريد حذف حدث "${item.action}"?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(ctx);
//               setState(() => _isLoading = true);
//               try {
//                 await context
//                     .read<PreventiveProvider>()
//                     .deletePreventiveItem(item.id!);
//                 ReusableToast.showToast(
//                   message: 'تم حذف الحدث بنجاح',
//                   bgColor: Colors.green,
//                   textColor: Colors.white,
//                   fontSize: 14,
//                 );
//               } catch (e) {
//                 ReusableToast.showToast(
//                   message: 'Error: $e',
//                   bgColor: Colors.red,
//                   textColor: Colors.white,
//                   fontSize: 14,
//                 );
//               } finally {
//                 setState(() => _isLoading = false);
//               }
//             },
//             child: const Text('حذف', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context, listen: false);
//     final colorScheme = Theme.of(context).colorScheme;
//     final isAdmin = userProvider.currentUser?.role == 'ADMIN' ||
//         userProvider.currentUser?.role == 'MANAGER';
//     final selectedIndex = _selectedDrawerIndex;

//     return ResponsiveScaffold(
//       topNavBar: buildRoleTopNavBar(context, selectedIndex),
//       sidebarContent: buildAppSidebar(
//         context: context,
//         selectedIndex: selectedIndex,
//       ),
//       appBar: AppBar(
//         leading: const SizedBox.shrink(),
//         backgroundColor: Colors.transparent,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh, color: colorScheme.onSurface),
//             onPressed: _fetchData,
//           ),
//         ],
//       ),
//       // AFTER — FAB only shows for admins
//       floatingActionButton: Consumer<AboutAppProvider>(
//         builder: (context, aboutAppProvider, child) {
//           if (!aboutAppProvider.isAdmin || _selectedAppName == null) {
//             return const SizedBox.shrink();
//           }
//           return FloatingActionButton.extended(
//             onPressed: () => _showAddEditDialog(appName: _selectedAppName!),
//             icon: const Icon(Icons.add),
//             label: const Text('اضافة حدث'),
//           );
//         },
//       ),
//       // floatingActionButton: _selectedAppName != null
//       //     ? FloatingActionButton.extended(
//       //         onPressed: () => _showAddEditDialog(appName: _selectedAppName!),
//       //         icon: const Icon(Icons.add),
//       //         label: const Text('اضافة حدث'),
//       //       )
//       //     : null,
//       body: ResponsiveContentContainer(
//         child: Consumer2<AboutAppProvider, PreventiveProvider>(
//           builder: (context, aboutAppProvider, preventiveProvider, child) {
//             if (aboutAppProvider.isLoading ||
//                 preventiveProvider.isLoadingItems ||
//                 _isLoading) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             final appNames = aboutAppProvider.aboutApps
//                 .map((a) => a.appName)
//                 .toSet()
//                 .toList();

//             if (appNames.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.apps_outlined,
//                         size: 80, color: Colors.grey.shade300),
//                     const SizedBox(height: 16),
//                     Text(
//                       'عفو لا يوجد تطبيقات',
//                       style:
//                           TextStyle(fontSize: 18, color: Colors.grey.shade600),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'فضلا أضف التطبيقات أولا',
//                       style: TextStyle(color: Colors.grey.shade500),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return Column(
//               children: [
//                 // Horizontal app name list
//                 Container(
//                   height: 60,
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: Listener(
//                     onPointerSignal: (event) {
//                       if (event is PointerScrollEvent) {
//                         final currentOffset =
//                             _horizontalScrollController.offset;
//                         final newOffset =
//                             (currentOffset + event.scrollDelta.dy).clamp(
//                           _horizontalScrollController.position.minScrollExtent,
//                           _horizontalScrollController.position.maxScrollExtent,
//                         );
//                         _horizontalScrollController.jumpTo(newOffset);
//                       }
//                     },
//                     child: ListView.builder(
//                       controller: _horizontalScrollController,
//                       scrollDirection: Axis.horizontal,
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       itemCount: appNames.length,
//                       itemBuilder: (context, index) {
//                         final appName = appNames[index];
//                         final isSelected = _selectedAppName == appName;

//                         return Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: FilterChip(
//                             selected: isSelected,
//                             label: Text(
//                               appName,
//                               strutStyle: StrutStyle(
//                                 fontFamily: 'Cairo',
//                               ),
//                             ),
//                             avatar: Icon(
//                               Icons.apps,
//                               size: 18,
//                               color: isSelected
//                                   ? Colors.white
//                                   : Theme.of(context).colorScheme.primary,
//                             ),
//                             selectedColor:
//                                 Theme.of(context).colorScheme.primary,
//                             checkmarkColor: Colors.white,
//                             labelStyle: TextStyle(
//                               fontFamily: 'Cairo',
//                               color: isSelected ? Colors.white : Colors.black87,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             onSelected: (selected) {
//                               setState(() {
//                                 _selectedAppName = selected ? appName : null;
//                               });
//                             },
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),

//                 // Divider
//                 const Divider(height: 1),

//                 // Actions list for selected app
//                 Expanded(
//                   child: _selectedAppName == null
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.touch_app_outlined,
//                                 size: 64,
//                                 color: Colors.grey.shade300,
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'أختر التطبيق اولا',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'اضافة حدث وقائى للتطبيق المحدد',
//                                 style: TextStyle(
//                                   color: Colors.grey.shade500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : _buildActionsList(_selectedAppName!),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildActionsList(String appName) {
//     return Consumer<PreventiveProvider>(
//       builder: (context, provider, child) {
//         final items = provider.preventiveItems
//             .where((item) => item.appName == appName)
//             .toList();

//         if (items.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.check_circle_outline,
//                   size: 64,
//                   color: Colors.grey.shade300,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'لا يوجد حدث وقائى للتطبيق $appName',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'اضافة حدث وقائى,إضغط +',
//                   style: TextStyle(
//                     color: Colors.grey.shade500,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: items.length,
//           itemBuilder: (context, index) {
//             final item = items[index];
//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 2,
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(16),
//                 onTap: () => _showAddEditDialog(item: item, appName: appName),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           color: Theme.of(context)
//                               .colorScheme
//                               .primary
//                               .withValues(alpha: 0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           Icons.build,
//                           color: Theme.of(context).colorScheme.primary,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           item.action,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                       Consumer<AboutAppProvider>(
//                         builder: (context, provider, child) {
//                           return provider.isAdmin
//                               ? IconButton(
//                                   icon: const Icon(Icons.delete_outline,
//                                       color: Colors.red),
//                                   onPressed: () => _deleteItem(item),
//                                 )
//                               : SizedBox.shrink();
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/responsive/app_sidebar.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_form_container.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_scaffold.dart';
import 'package:tasks_app/common_widgets/responsive/top_nav_bar.dart';
import 'package:tasks_app/controller/preventive_provider.dart';
import 'package:tasks_app/controller/about_app_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/models/preventive_item_model.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/services/connectivity_service.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';

class PreventiveItemScreen extends StatefulWidget {
  const PreventiveItemScreen({super.key});

  @override
  State<PreventiveItemScreen> createState() => _PreventiveItemScreenState();
}

class _PreventiveItemScreenState extends State<PreventiveItemScreen> {
  final ConnectivityService _connectivity = ConnectivityService();
  final TextEditingController _actionController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  bool _isLoading = false;
  String? _selectedAppName;
  int _selectedDrawerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Read selected index from route arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['selectedIndex'] != null) {
        setState(() {
          _selectedDrawerIndex = args['selectedIndex'] as int;
        });
      }
      _checkUserStatus();
      _fetchData();
    });
  }

  @override
  void dispose() {
    _actionController.dispose();
    _horizontalScrollController.dispose();
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
    final department = userProvider.currentUser?.department;

    if (department != null && department.isNotEmpty) {
      await context.read<AboutAppProvider>().fetchAppsByDepartment(department);
      await context
          .read<PreventiveProvider>()
          .fetchAllPreventiveItemsByDepartment(department);

      // If no results, try default department
      final provider = context.read<PreventiveProvider>();
      if (provider.preventiveItems.isEmpty) {
        await context
            .read<PreventiveProvider>()
            .fetchAllPreventiveItemsByDepartment('IT');
      }
    } else {
      await context.read<AboutAppProvider>().fetchAllAboutApps();
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

  List<PreventiveItemModel> _getItemsForApp(String appName) {
    final provider = context.read<PreventiveProvider>();
    return provider.preventiveItems
        .where((item) => item.appName == appName)
        .toList();
  }

  // ---------------------------------------------------------------------
  // FIX: role check added. Non-admin/manager users can still open the
  // dialog by tapping the card (to view the event text), but the input
  // becomes read-only and the "تحديث" / "اضافة" button is completely
  // removed from the layout (not just hidden) so they cannot submit.
  // ---------------------------------------------------------------------
  void _showAddEditDialog(
      {PreventiveItemModel? item, required String appName}) async {
    if (item != null) {
      _actionController.text = item.action;
    } else {
      _actionController.clear();
    }

    final bool isAdmin = context.read<AboutAppProvider>().isAdmin;

    showResponsiveForm(
      context: context,
      title: item == null ? 'إضافة حدث $appName' : 'تحديث حدث $appName',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _actionController,
            readOnly: !isAdmin, // users can view only, not edit the text
            decoration: InputDecoration(
              labelText: 'الحدث',
              hintText: 'فضلا ادخل الحدث',
              prefixIcon: const Icon(Icons.build),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Only admins/managers see the update/add button.
          if (isAdmin)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveItem(item, appName),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(item == null ? 'اضافة' : 'تحديث'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveItem(PreventiveItemModel? item, String appName) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      await ConnectionDialogService.showNoInternetDialog(
        context,
      );
      return;
    }
    if (_actionController.text.isEmpty) {
      ReusableToast.showToast(
        message: 'يرجى ادخال الحدث',
        bgColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 14,
      );
      return;
    }

    Navigator.pop(context);
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final department = userProvider.currentUser?.department ?? 'IT';

    try {
      final provider = context.read<PreventiveProvider>();
      if (item == null) {
        await provider.addPreventiveItem(
            appName, _actionController.text, department);
        ReusableToast.showToast(
          message: 'تم اضافة الحدث بنجاح',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 14,
        );
      } else {
        await provider.updatePreventiveItem(
            item.id!, appName, _actionController.text, department);
        ReusableToast.showToast(
          message: 'تم تحديث الحدث بنجاح',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 14,
        );
      }
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

  Future<void> _deleteItem(PreventiveItemModel item) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      await ConnectionDialogService.showNoInternetDialog(
        context,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف حدث'),
        content: Text('هل تريد حذف حدث "${item.action}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await context
                    .read<PreventiveProvider>()
                    .deletePreventiveItem(item.id!);
                ReusableToast.showToast(
                  message: 'تم حذف الحدث بنجاح',
                  bgColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 14,
                );
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
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
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
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onSurface),
            onPressed: _fetchData,
          ),
        ],
      ),
      floatingActionButton: Consumer<AboutAppProvider>(
        builder: (context, aboutAppProvider, child) {
          if (!aboutAppProvider.isAdmin || _selectedAppName == null) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _showAddEditDialog(appName: _selectedAppName!),
            icon: const Icon(Icons.add),
            label: const Text('اضافة حدث'),
          );
        },
      ),
      body: ResponsiveContentContainer(
        child: Consumer2<AboutAppProvider, PreventiveProvider>(
          builder: (context, aboutAppProvider, preventiveProvider, child) {
            if (aboutAppProvider.isLoading ||
                preventiveProvider.isLoadingItems ||
                _isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final appNames = aboutAppProvider.aboutApps
                .map((a) => a.appName)
                .toSet()
                .toList();

            if (appNames.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apps_outlined,
                        size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'عفو لا يوجد تطبيقات',
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'فضلا أضف التطبيقات أولا',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Horizontal app name list
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        final currentOffset =
                            _horizontalScrollController.offset;
                        final newOffset =
                            (currentOffset + event.scrollDelta.dy).clamp(
                          _horizontalScrollController.position.minScrollExtent,
                          _horizontalScrollController.position.maxScrollExtent,
                        );
                        _horizontalScrollController.jumpTo(newOffset);
                      }
                    },
                    child: ListView.builder(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: appNames.length,
                      itemBuilder: (context, index) {
                        final appName = appNames[index];
                        final isSelected = _selectedAppName == appName;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(
                              appName,
                              strutStyle: StrutStyle(
                                fontFamily: 'Cairo',
                              ),
                            ),
                            avatar: Icon(
                              Icons.apps,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              fontFamily: 'Cairo',
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedAppName = selected ? appName : null;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Divider
                const Divider(height: 1),

                // Actions list for selected app
                Expanded(
                  child: _selectedAppName == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'أختر التطبيق اولا',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'اضافة حدث وقائى للتطبيق المحدد',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildActionsList(_selectedAppName!),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionsList(String appName) {
    return Consumer<PreventiveProvider>(
      builder: (context, provider, child) {
        final items = provider.preventiveItems
            .where((item) => item.appName == appName)
            .toList();

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا يوجد حدث وقائى للتطبيق $appName',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضافة حدث وقائى,إضغط +',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showAddEditDialog(item: item, appName: appName),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.build,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.action,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Consumer<AboutAppProvider>(
                        builder: (context, provider, child) {
                          return provider.isAdmin
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _deleteItem(item),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
