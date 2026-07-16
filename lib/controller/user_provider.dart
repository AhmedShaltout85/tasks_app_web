import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../newtork_repos/remote_repo/api_repos/api_network_user_repos_impl.dart';
import '../newtork_repos/remote_repo/api_repos/dio_client.dart';
import '../services/auth_state_manager.dart';
import '../utils/auth_status.dart';
import '../utils/jwt_helper.dart';
import '../utils/web_helper/web_helper.dart';
import 'local_control/cache_helper.dart';

class UserProvider with ChangeNotifier, WidgetsBindingObserver {
  final ApiNetworkUserReposImpl _api = ApiNetworkUserReposImpl();
  final AuthStateManager _auth = AuthStateManager.instance;

  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isUsersLoading = false;
  String? _error;
  AuthStatus _authStatus = AuthStatus.authenticated;
  StreamSubscription<void>? _focusSubscription;
  StreamSubscription<AuthStatus>? _statusSubscription;
  bool _resumeCheckInProgress = false;

  UserProvider() {
    WidgetsBinding.instance.addObserver(this);
    _setupCallbacks();
    _setupWebFocusListener();
    _listenToAuthStatus();
    _init();
  }

  @override
  void dispose() {
    _focusSubscription?.cancel();
    _statusSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTokenOnResume();
    }
  }

  void _listenToAuthStatus() {
    _statusSubscription = _auth.statusStream.listen((status) {
      _authStatus = status;
      if (status == AuthStatus.expired) {
        _currentUser = null;
        _users = [];
        notifyListeners();
      } else if (status == AuthStatus.refreshed) {
        _loadCurrentUserFromCache();
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> _checkTokenOnResume() async {
    if (_resumeCheckInProgress) {
      log('Resume check already in progress, skipping duplicate trigger');
      return;
    }
    _resumeCheckInProgress = true;
    try {
      if (!_auth.isAuthenticated) return;
      final expiry = _auth.tokenExpiry;
      if (expiry == null) return;
      if (expiry.isBefore(DateTime.now())) {
        log('Token expired while app was inactive, attempting refresh on resume...');
        final result = await _auth.attemptRefresh();
        if (result == RefreshResult.success) {
          log('Token refreshed successfully on resume');
          await _restoreCachedUser();
        } else if (result == RefreshResult.rejected) {
          log('Refresh token rejected on resume, clearing session');
          await clearUserData();
        } else {
          log('Refresh on resume failed (transient), periodic timer will retry');
          if (_auth.token != null) {
            DioClient().scheduleTokenRefresh(_auth.token!);
          }
        }
      } else {
        log('Token still valid on resume, rescheduling proactive refresh');
        if (_auth.token != null) {
          DioClient().scheduleTokenRefresh(_auth.token!);
        }
      }
    } finally {
      _resumeCheckInProgress = false;
    }
  }

  void _setupWebFocusListener() {
    _focusSubscription = onWindowFocus(() {
      log('Web window focused — checking token validity');
      _checkTokenOnResume();
    });
  }

  void _setupCallbacks() {
    final dioClient = DioClient();
    dioClient.setCallbacks(
      onTokensRefreshed: (newAccessToken, newRefreshToken, newExpiry) async {
        await _auth.notifyTokenRefreshed(
            newAccessToken, newRefreshToken, newExpiry);
        await updateLocalTokenState();
      },
      onSessionExpired: () async {
        await _auth.notifySessionExpired();
        await clearUserData();
      },
    );
  }

  Future<void> updateLocalTokenState() async {
    DioClient().setToken(_auth.token ?? '');
    DioClient().setRefreshToken(_auth.refreshToken ?? '');
  }

  bool get isInitializing => _isInitializing;
  AuthStatus get authStatus => _authStatus;

  Future<void> _init() async {
    await _auth.initialize();
    await _loadUserFromCache();
    _isInitializing = false;
    log('UserProvider init complete - user: ${_currentUser?.username}, role: ${_currentUser?.role}');
    notifyListeners();
  }

  Future<void> _loadUserFromCache() async {
    final savedUserData = CacheHelper.getString(key: 'current_user');
    if (savedUserData != null) {
      try {
        final userMap = jsonDecode(savedUserData);
        _currentUser = UserModel.fromJson(userMap);
        log('User data restored from cache: ${_currentUser?.displayName}');
        if (_auth.token != null) {
          DioClient().scheduleTokenRefresh(_auth.token!);
        }
      } catch (e) {
        log('Failed to parse cached user data: $e');
        await clearUserData();
      }
    } else if (_auth.isAuthenticated) {
      log('No cached user data but auth tokens exist, clearing session');
      await clearUserData();
    }
  }

  void _loadCurrentUserFromCache() {
    final savedUserData = CacheHelper.getString(key: 'current_user');
    if (savedUserData != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(savedUserData));
      } catch (_) {}
    }
  }

  Future<void> _restoreCachedUser() async {
    final savedUserData = CacheHelper.getString(key: 'current_user');
    if (savedUserData != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(savedUserData));
        if (_auth.token != null) {
          DioClient().scheduleTokenRefresh(_auth.token!);
        }
        notifyListeners();
      } catch (e) {
        log('Failed to parse cached user data: $e');
        await clearUserData();
      }
    }
  }

  Future<void> _saveUserToCache(UserModel user) async {
    await CacheHelper.saveData(
        key: 'current_user', value: jsonEncode(user.toJson()));
  }

  Future<void> _clearUserCache() async {
    await CacheHelper.removeData(key: 'current_user');
  }

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  bool get isUsersLoading => _isUsersLoading;
  bool get isAnyLoading => _isLoading || _isUsersLoading;
  String? get error => _error;
  String? get token => _auth.token;
  String? get refreshToken => _auth.refreshToken;
  DateTime? get tokenExpiry => _auth.tokenExpiry;

  Future<void> clearUserData() async {
    _currentUser = null;
    _users = [];
    _error = null;
    await _auth.clearSession();
    await _clearUserCache();
    DioClient().cancelTimer();
    notifyListeners();
  }

  Future<void> signUp({
    required String displayName,
    required String username,
    required String password,
    required String role,
    required String department,
  }) async {
    _setLoading(true);
    notifyListeners();
    try {
      await _api.signUp(
        displayName: displayName,
        username: username,
        password: password,
        role: role,
        department: department,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    notifyListeners();
    try {
      final response = await _api.signIn(
        username: username,
        password: password,
      );
      log('SignIn response received');
      final token = response['token'] as String?;
      if (token == null || JwtHelper.extractExpiry(token) == null) {
        log('Server returned malformed token, sign-in failed');
        _error = 'Invalid server response';
        return;
      }

      final refreshToken = response['refreshToken'] as String?;
      if (refreshToken == null) {
        log('WARNING: Backend did not return a refreshToken. Auto-refresh will not work.');
      }

      await _auth.setTokensFromSignIn(token, refreshToken ?? '');
      await updateLocalTokenState();
      if (_auth.token != null) {
        DioClient().scheduleTokenRefresh(_auth.token!);
      }

      _currentUser = UserModel.fromJson(response);
      await _saveUserToCache(_currentUser!);
      log('Current user set: ${_currentUser?.displayName}');
      _error = null;
    } on DioException catch (e) {
      log('SignIn error: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        final data = e.response?.data;
        _error = data['error'] ?? 'Invalid username or password';
      } else {
        _error = e.message ?? 'Login failed';
      }
    } catch (e) {
      log('SignIn error: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _api.signOut(refreshToken: _auth.refreshToken);
    } catch (e) {
      // Ignore signout API error
    }
    await clearUserData();
  }

  Future<void> fetchAllUsers() async {
    _setUsersLoading(true);
    notifyListeners();
    try {
      _users = await _api.getAllUsers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setUsersLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchUserById(int id) async {
    _setUsersLoading(true);
    notifyListeners();
    try {
      _currentUser = await _api.getUserById(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setUsersLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchUsersByDepartment(String department) async {
    _setUsersLoading(true);
    notifyListeners();
    try {
      _users = await _api.getUsersByDepartment(department);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setUsersLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchUsersByRole(String role) async {
    _setUsersLoading(true);
    notifyListeners();
    try {
      _users = await _api.getUsersByRole(role);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setUsersLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchEnabledUsersByRole(String role, bool enabled) async {
    log('fetchEnabledUsersByRole called - role: $role, enabled: $enabled');
    _isUsersLoading = true;
    notifyListeners();
    try {
      _users = await _api.getEnabledUsersByRole(role, enabled);
      log('Users fetched successfully: ${_users.length}');
      _error = null;
    } catch (e) {
      log('Error fetching users: $e');
      _error = e.toString();
    } finally {
      _isUsersLoading = false;
      notifyListeners();
    }
  }

  Future<void> setUserEnabled(int id, bool enabled) async {
    log('setUserEnabled called - id: $id, enabled: $enabled');
    _isLoading = true;
    notifyListeners();
    try {
      await _api.setUserEnabled(id, enabled);
      final index = _users.indexWhere((u) => u.id == id);
      log('Index found: $index');
      if (index != -1) {
        _users[index] = _users[index].copyWith(enabled: enabled);
      }
      if (_currentUser?.id == id) {
        _currentUser = _currentUser!.copyWith(enabled: enabled);
      }
      _error = null;
    } catch (e) {
      log('Error in setUserEnabled: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(int id) async {
    _setLoading(true);
    notifyListeners();
    try {
      await _api.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    notifyListeners();
    try {
      await _api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> forgotPassword({
    required String username,
    required String newPassword,
  }) async {
    _setLoading(true);
    notifyListeners();
    try {
      await _api.forgotPassword(
        username: username,
        newPassword: newPassword,
      );
      _error = null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 400) {
        final data = e.response?.data;
        _error = data['error'] ?? data['message'] ?? 'User not found';
      } else {
        _error = e.message ?? 'Failed to reset password';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setUsersLoading(bool value) {
    _isUsersLoading = value;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
