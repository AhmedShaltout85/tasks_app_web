import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_app/common_widgets/responsive/empty_state_widget.dart';
import 'package:tasks_app/common_widgets/responsive/responsive_content_container.dart';
import 'package:tasks_app/common_widgets/resuable_widgets/reusable_toast.dart';
import 'package:tasks_app/controller/theme_provider.dart';
import 'package:tasks_app/controller/user_provider.dart';
import 'package:tasks_app/models/user_model.dart';
import 'package:tasks_app/services/connection_dialog_service.dart';
import 'package:tasks_app/services/connectivity_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ConnectivityService _connectivity = ConnectivityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsers();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      // Use the dialog service with retry option
      await ConnectionDialogService.showNoInternetDialog(
        context,
        onRetry: _fetchUsers, // Retry the entire signup process
      );
      return;
    }
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    log('Current user: ${userProvider.currentUser?.displayName}');
    log('Current user department: ${userProvider.currentUser?.department}');
    log('Token: ${userProvider.token}');

    final department = userProvider.currentUser?.department;

    if (department != null && department.isNotEmpty) {
      log('Fetching users by department: $department');
      await userProvider.fetchUsersByDepartment(department);
    } else {
      log('Fetching all users');
      await userProvider.fetchAllUsers();
    }
    log('Users loaded: ${userProvider.users.length}');
  }

  Future<void> _showDisableEnableDialog(UserModel user, bool enable) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      // Create a wrapper function
      void retryAction() {
        _showDisableEnableDialog(user, enable);
      }

      await ConnectionDialogService.showNoInternetDialog(
        context,
        onRetry: retryAction,
      );
      return;
    }

    final userId = user.id;
    if (userId == null) return;

    await context.read<UserProvider>().setUserEnabled(userId, enable);

    if (mounted) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.error != null) {
        ReusableToast.showToast(
          message: userProvider.error!,
          bgColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16,
        );
        userProvider.clearError();
      } else {
        ReusableToast.showToast(
          message: enable
              ? 'User enabled successfully'
              : 'User disabled successfully',
          bgColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(UserModel user) async {
    final hasConnection = await _connectivity.hasConnection();
    if (!hasConnection) {
      // Create a wrapper function
      void retryAction() {
        _showDeleteConfirmation(user);
      }

      await ConnectionDialogService.showNoInternetDialog(
        context,
        onRetry: retryAction,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Delete User?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${user.displayName}"? This action cannot be undone.',
        ),
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
      final userId = user.id;
      if (userId == null) return;

      await context.read<UserProvider>().deleteUser(userId);

      if (mounted) {
        final userProvider = context.read<UserProvider>();
        if (userProvider.error != null) {
          ReusableToast.showToast(
            message: userProvider.error!,
            bgColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16,
          );
          userProvider.clearError();
        } else {
          ReusableToast.showToast(
            message: 'User deleted successfully',
            bgColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16,
          );
        }
      }
    }
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      return user.displayName.toLowerCase().contains(_searchQuery) ||
          user.username.toLowerCase().contains(_searchQuery) ||
          (user.department ?? '').toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        title: const Text('إدارة المستخدمين'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: ResponsiveContentContainer(
        child: Consumer<UserProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading users...',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.error, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Oops! Something went wrong',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchUsers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final filteredUsers = _getFilteredUsers(provider.users);

            return Column(
              children: [
                Container(
                  color: isDark ? colorScheme.surface : Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      prefixIcon:
                          Icon(Icons.search, color: colorScheme.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (provider.users.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${filteredUsers.length} ${filteredUsers.length == 1 ? 'user' : 'users'}',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty &&
                            filteredUsers.length != provider.users.length)
                          Text(
                            ' (${provider.users.length} total)',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[600] : Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? EmptyStateWidget(
                          icon: _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.people_outline,
                          title: _searchQuery.isNotEmpty
                              ? 'No users found'
                              : 'No users yet',
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'No users available',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color:
                                    isDark ? colorScheme.surface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: isDark
                                    ? Border.all(
                                        color: Colors.grey.shade800, width: 1)
                                    : null,
                                boxShadow: isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primary,
                                  radius: 24,
                                  child: Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.black87
                                          : Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.username,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(user.role)
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user.role ?? 'USER',
                                            style: TextStyle(
                                              color: _getRoleColor(user.role),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: user.enabled == true
                                                ? Colors.green
                                                    .withValues(alpha: 0.1)
                                                : Colors.red
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user.enabled == true
                                                ? 'Active'
                                                : 'Inactive',
                                            style: TextStyle(
                                              color: user.enabled == true
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          user.enabled == true
                                              ? Icons.block
                                              : Icons.check_circle,
                                          color: Colors.orange,
                                        ),
                                        tooltip: user.enabled == true
                                            ? 'Disable'
                                            : 'Enable',
                                        onPressed: () =>
                                            _showDisableEnableDialog(
                                                user, user.enabled != true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Delete',
                                        onPressed: () =>
                                            _showDeleteConfirmation(user),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'ADMIN':
        return Colors.blue;
      case 'MANAGER':
        return Colors.purple;
      case 'USER':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
