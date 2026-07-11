import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import '../../controller/complaint_provider.dart';
import '../../controller/daily_task_provider.dart';
import '../../controller/user_provider.dart';
import '../../models/daily_task_model.dart';
import '../../models/user_model.dart';
import '../../services/connectivity_service.dart';
import '../../utils/app_colors.dart';
// import '../../utils/app_route.dart';
import '../../common_widgets/custom_widgets/custom_text.dart';
import '../../common_widgets/custom_widgets/custom_loading.dart';
import '../../common_widgets/custom_widgets/custom_complaint_card.dart';
import '../../common_widgets/custom_widgets/custom_dropdown.dart';
import '../../common_widgets/custom_widgets/custom_button.dart';
import '../../models/complaint_model.dart';
import '../../common_widgets/responsive/app_sidebar.dart';
import '../../common_widgets/responsive/responsive_content_container.dart';
import '../../common_widgets/responsive/responsive_scaffold.dart';
import '../../common_widgets/responsive/top_nav_bar.dart';

class ManageComplaintsScreen extends StatefulWidget {
  const ManageComplaintsScreen({super.key});

  @override
  State<ManageComplaintsScreen> createState() => _ManageComplaintsScreenState();
}

class _ManageComplaintsScreenState extends State<ManageComplaintsScreen> {
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  int _selectedDrawerIndex = 9;

  @override
  void initState() {
    super.initState();
    // Read selected index from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['selectedIndex'] != null) {
        setState(() {
          _selectedDrawerIndex = args['selectedIndex'] as int;
        });
      }
    });
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final connected = await _connectivityService.hasConnection();
      if (!mounted) return;
      if (!connected) {
        _showNoInternetDialog();
        return;
      }
      if (!mounted) return;

      final userProvider = context.read<UserProvider>();
      final department = userProvider.currentUser?.department;

      if (department != null && department.isNotEmpty) {
        context.read<ComplaintProvider>().fetchByDepartmentAndIsEnable(
              department,
              true,
            );
      } else {
        context.read<ComplaintProvider>().fetchAllComplaints();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      topNavBar: buildRoleTopNavBar(context, _selectedDrawerIndex),
      sidebarContent: buildAppSidebar(
        context: context,
        selectedIndex: _selectedDrawerIndex,
      ),
      appBar: _buildAppBar(),
      body: ResponsiveContentContainer(
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      leading: const SizedBox.shrink(),
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: _showFilterBottomSheet,
          icon: Icon(Icons.filter_list, color: colorScheme.primary),
          tooltip: 'تصفية',
        ),
        IconButton(
          onPressed: _loadComplaints,
          icon: Icon(Icons.refresh, color: colorScheme.primary),
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<ComplaintProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const CustomLoading(size: 40);
        if (provider.error != null) return _buildErrorState(provider);
        if (provider.complaints.isEmpty) return _buildEmptyState();
        return _buildComplaintList(provider);
      },
    );
  }

  Widget _buildErrorState(ComplaintProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 80, color: AppColors.errorColor),
            const SizedBox(height: 16),
            CustomText(
              text: provider.error!,
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: AppColors.errorColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomElevatedButton(
              text: 'إعادة المحاولة',
              onTap: () => _loadComplaints(),
              color: AppColors.primaryColor,
              textColor: AppColors.whiteColor,
              fontSize: 14,
              height: 48,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 100,
              color: AppColors.hintColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const CustomText(
              text: 'لا توجد شكاوى',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.grayColor,
            ),
            const SizedBox(height: 8),
            const CustomText(
              text: 'اضغط على + لإضافة شكوى جديدة',
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.hintColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintList(ComplaintProvider provider) {
    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1024) {
            return _buildResponsiveGrid(provider.complaints, maxWidth: 1024);
          } else if (constraints.maxWidth > 600) {
            return _buildResponsiveGrid(provider.complaints);
          }
          return _buildMobileList(provider.complaints);
        },
      ),
    );
  }

  Widget _buildMobileList(List<ComplaintModel> complaints) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: complaints.length,
      itemBuilder: (context, index) => _buildCard(complaints[index]),
    );
  }

  Widget _buildResponsiveGrid(List<ComplaintModel> complaints,
      {double? maxWidth}) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32;
        final cardWidth = (availableWidth - 16) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: complaints
                .map((complaint) => SizedBox(
                      width: cardWidth,
                      child: _buildCard(complaint),
                    ))
                .toList(),
          ),
        );
      },
    );

    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildCard(ComplaintModel complaint) {
    return CustomComplaintCard(
      complaint: complaint,
      onDelete: () => _confirmDelete(complaint),
      onCreateTask: complaint.isEnable
          ? () => _showCreateTaskBottomSheet(complaint)
          : null,
    );
  }

  void _confirmDelete(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الشكوى؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ComplaintProvider>().deleteComplaint(complaint.id!);
            },
            child: const Text('حذف',
                style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.wifi_off, size: 60, color: AppColors.errorColor),
        title: const Text('لا يوجد اتصال بالإنترنت'),
        content: const Text('تحقق من اتصالك بالإنترنت وأعد المحاولة'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadComplaints();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // ─── Create Task Bottom Sheet ────────────────────────────────────────

  void _showCreateTaskBottomSheet(ComplaintModel complaint) {
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    final department = currentUser?.department ?? complaint.department;

    userProvider.fetchUsersByDepartment(department);

    String? selectedAssignedTo;
    String selectedPriority = 'MEDIUM';
    List<String> selectedCoOperators = [];
    DateTime expectedDate = DateTime.now().add(const Duration(days: 1));
    final taskNoteController = TextEditingController(
      text: 'سوفتوير - ${complaint.empName} - ${complaint.empMobile}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return _buildCreateTaskContent(
            complaint: complaint,
            currentUser: currentUser,
            userProvider: userProvider,
            selectedAssignedTo: selectedAssignedTo,
            selectedPriority: selectedPriority,
            selectedCoOperators: selectedCoOperators,
            expectedDate: expectedDate,
            taskNoteController: taskNoteController,
            onAssignedToChanged: (value) =>
                setModalState(() => selectedAssignedTo = value),
            onPriorityChanged: (value) =>
                setModalState(() => selectedPriority = value ?? 'MEDIUM'),
            onCoOperatorsChanged: (value) =>
                setModalState(() => selectedCoOperators = value),
            onDateChanged: (value) => setModalState(() => expectedDate = value),
            onSubmit: () => _submitCreateTask(
              complaint: complaint,
              currentUser: currentUser,
              assignedTo: selectedAssignedTo,
              priority: selectedPriority,
              coOperators: selectedCoOperators,
              expectedDate: expectedDate,
              taskNote: taskNoteController.text,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateTaskContent({
    required ComplaintModel complaint,
    required UserModel? currentUser,
    required UserProvider userProvider,
    required String? selectedAssignedTo,
    required String selectedPriority,
    required List<String> selectedCoOperators,
    required DateTime expectedDate,
    required TextEditingController taskNoteController,
    required ValueChanged<String?> onAssignedToChanged,
    required ValueChanged<String?> onPriorityChanged,
    required ValueChanged<List<String>> onCoOperatorsChanged,
    required ValueChanged<DateTime> onDateChanged,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              text: 'إنشاء مهمة من الشكوى',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Complaint data as read-only text
            _buildReadOnlyField('اسم المهمة', complaint.complaintName),
            const SizedBox(height: 8),
            _buildReadOnlyField('المنظومة', complaint.appName),
            const SizedBox(height: 8),
            _buildReadOnlyField('مخصصة بواسطة', complaint.empName),
            const SizedBox(height: 8),
            _buildReadOnlyField('المكان الرئيسي', complaint.placeName),
            const SizedBox(height: 8),
            _buildReadOnlyField('المكان الفرعي',
                complaint.subPlace != 'none' ? complaint.subPlace : 'لا يوجد'),
            const SizedBox(height: 8),
            TextField(
              controller: taskNoteController,
              decoration: InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Assigned To dropdown (USER role in department)
            Consumer<UserProvider>(
              builder: (context, userProv, _) {
                final users = userProv.users
                    .where((u) => u.role == 'USER' && u.enabled == true)
                    .toList();
                return CustomDropdown(
                  label: 'مخصصة ل',
                  hint: 'اختر الموظف',
                  items: ['اختر الموظف', ...users.map((u) => u.displayName)],
                  value: selectedAssignedTo ?? 'اختر الموظف',
                  onChanged: (value) {
                    if (value == 'اختر الموظف') {
                      onAssignedToChanged(null);
                    } else {
                      onAssignedToChanged(value);
                    }
                  },
                  icon: Icons.person,
                );
              },
            ),
            const SizedBox(height: 12),

            // Priority dropdown
            CustomDropdown(
              label: 'الأهمية',
              hint: 'اختر الأهمية',
              items: ['HIGH', 'MEDIUM', 'LOW'],
              value: selectedPriority,
              onChanged: (value) => onPriorityChanged(value),
              icon: Icons.flag,
            ),
            const SizedBox(height: 12),

            // Co-operators multiselect
            Consumer<UserProvider>(
              builder: (context, userProv, _) {
                final users = userProv.users
                    .where((u) =>
                        u.role == 'USER' &&
                        u.enabled == true &&
                        u.displayName != selectedAssignedTo)
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.group,
                            size: 18, color: AppColors.primaryColor),
                        const SizedBox(width: 6),
                        const Text(
                          'المتعاونون',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackColor87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: users.isEmpty
                          ? const Text(
                              'لا يوجد مستخدمون متاحون',
                              style: TextStyle(
                                  color: AppColors.hintColor, fontSize: 14),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: users.map((user) {
                                final isSelected = selectedCoOperators
                                    .contains(user.displayName);
                                return FilterChip(
                                  label: Text(user.displayName),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    final newList =
                                        List<String>.from(selectedCoOperators);
                                    if (selected) {
                                      newList.add(user.displayName);
                                    } else {
                                      newList.remove(user.displayName);
                                    }
                                    onCoOperatorsChanged(newList);
                                  },
                                  selectedColor:
                                      AppColors.primaryColor.withOpacity(0.2),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Expected completion date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: expectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  onDateChanged(picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'توقع انتهاء المهمة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${expectedDate.day}/${expectedDate.month}/${expectedDate.year}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            CustomElevatedButton(
              text: 'إنشاء المهمة',
              onTap: onSubmit,
              color: AppColors.primaryColor,
              textColor: AppColors.whiteColor,
              fontSize: 16,
              height: 50,
              width: double.infinity,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrayColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grayColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.blackColor87,
            ),
          ),
        ],
      ),
    );
  }

  void _submitCreateTask({
    required ComplaintModel complaint,
    required UserModel? currentUser,
    required String? assignedTo,
    required String priority,
    required List<String> coOperators,
    required DateTime expectedDate,
    required String taskNote,
  }) async {
    if (assignedTo == null || assignedTo.isEmpty) {
      ReusableToast.showToast(
        message: 'يرجى اختيار الموظف المخصص له',
        bgColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16,
      );
      return;
    }

    Navigator.pop(context);

    final newTask = DailyTaskModel(
      taskTitle: complaint.complaintName,
      taskStatus: true,
      appName: complaint.appName,
      visitPlace: complaint.placeName,
      subPlace: complaint.subPlace != 'none' ? complaint.subPlace : 'لا يوجد',
      assignedTo: assignedTo,
      assignedBy: currentUser?.username ?? '',
      coOperator: coOperators,
      expectedCompletionDate: expectedDate,
      taskPriority: priority,
      taskNote: taskNote,
      isRemote: false,
      createdAt: DateTime.now(),
    );

    await context.read<DailyTaskProvider>().createTask(newTask);

    if (mounted) {
      final provider = context.read<DailyTaskProvider>();
      if (provider.error != null) {
        ReusableToast.showToast(
          message: provider.error!,
          bgColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16,
        );
        provider.clearError();
      } else {
        // Update the complaint to isEnable: false
        await context.read<ComplaintProvider>().updateComplaint(
              complaint.id!,
              complaint.copyWith(isEnable: false),
            );

        ReusableToast.showToast(
          message: 'تم إضافة المهمة بنجاح',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );

        _loadComplaints();
      }
    }
  }

  // ─── Filter Bottom Sheet ─────────────────────────────────────────────

  void _showFilterBottomSheet() {
    final provider = context.read<ComplaintProvider>();
    String? selectedApp;
    String? selectedDept;
    String? selectedEmp;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return _buildFilterContent(
            provider: provider,
            setModalState: setModalState,
            selectedApp: selectedApp,
            selectedDept: selectedDept,
            selectedEmp: selectedEmp,
            onAppChanged: (value) => setModalState(() => selectedApp = value),
            onDeptChanged: (value) => setModalState(() => selectedDept = value),
            onEmpChanged: (value) => setModalState(() => selectedEmp = value),
            onApply: () {
              _applyFilter(provider, selectedApp, selectedDept, selectedEmp);
              Navigator.pop(context);
            },
            onClear: () {
              provider.clearFilter();
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterContent({
    required ComplaintProvider provider,
    required StateSetter setModalState,
    required String? selectedApp,
    required String? selectedDept,
    required String? selectedEmp,
    required ValueChanged<String?> onAppChanged,
    required ValueChanged<String?> onDeptChanged,
    required ValueChanged<String?> onEmpChanged,
    required VoidCallback onApply,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CustomText(
            text: 'تصفية الشكاوى',
            fontSize: 18,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          CustomDropdown(
            label: 'تطبيق/نظام',
            hint: 'اختر التطبيق',
            items: ['الكل', ...provider.getUniqueAppNames()],
            value: selectedApp ?? 'الكل',
            onChanged: onAppChanged,
            icon: Icons.phone_android,
          ),
          const SizedBox(height: 12),
          CustomDropdown(
            label: 'القسم',
            hint: 'اختر القسم',
            items: ['الكل', ...provider.getUniqueDepartments()],
            value: selectedDept ?? 'الكل',
            onChanged: onDeptChanged,
            icon: Icons.business,
          ),
          const SizedBox(height: 12),
          CustomDropdown(
            label: 'اسم الموظف',
            hint: 'اختر الموظف',
            items: ['الكل', ...provider.getUniqueEmpNames()],
            value: selectedEmp ?? 'الكل',
            onChanged: onEmpChanged,
            icon: Icons.person,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  text: 'مسح',
                  onTap: onClear,
                  color: AppColors.grayColor,
                  textColor: AppColors.whiteColor,
                  fontSize: 14,
                  height: 48,
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomElevatedButton(
                  text: 'تطبيق',
                  onTap: onApply,
                  color: AppColors.primaryColor,
                  textColor: AppColors.whiteColor,
                  fontSize: 14,
                  height: 48,
                  width: double.infinity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _applyFilter(
    ComplaintProvider provider,
    String? app,
    String? dept,
    String? emp,
  ) {
    if (app != null) {
      provider.filterByAppName(app);
    } else if (dept != null) {
      provider.filterByDepartment(dept);
    } else if (emp != null) {
      provider.filterByEmpName(emp);
    } else {
      provider.clearFilter();
    }
  }
}
