import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../newtork_repos/remote_repo/api_repos/api_network_user_repos_impl.dart';
import '../newtork_repos/remote_repo/api_repos/dio_client.dart';
import '../utils/jwt_helper.dart';
import '../utils/web_helper/web_helper.dart';
import 'local_control/cache_helper.dart';

class UserProvider with ChangeNotifier, WidgetsBindingObserver {
  final ApiNetworkUserReposImpl _api = ApiNetworkUserReposImpl();

  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isUsersLoading = false;
  String? _error;
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  StreamSubscription<void>? _focusSubscription;

  UserProvider() {
    WidgetsBinding.instance.addObserver(this);
    _setupCallbacks();
    _setupWebFocusListener();
    _init();
  }

  @override
  void dispose() {
    _focusSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTokenOnResume();
    }
  }

  Future<void> _checkTokenOnResume() async {
    if (_token == null || _tokenExpiry == null) return;

    if (_tokenExpiry!.isBefore(DateTime.now())) {
      log('Token expired while app was inactive, attempting refresh on resume...');
      if (_refreshToken != null) {
        final refreshed = await _attemptRefreshOnStartup();
        if (refreshed) {
          log('Token refreshed successfully on resume');
          await _restoreCachedUser();
          return;
        }
        // Transient failure — DioClient periodic timer will retry
        log('Refresh on resume failed (transient), periodic timer will retry');
        DioClient().scheduleTokenRefresh(_token!);
      } else {
        log('No refresh token available on resume, clearing session');
        await clearUserData();
      }
    } else {
      log('Token still valid on resume, rescheduling proactive refresh');
      DioClient().scheduleTokenRefresh(_token!);
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
        await updateTokens(newAccessToken, newRefreshToken, newExpiry);
      },
      onSessionExpired: () async {
        await clearUserData();
      },
    );
  }

  bool get isInitializing => _isInitializing;

  Future<void> _init() async {
    await _loadTokenFromCache();
    _isInitializing = false;
    log('UserProvider init complete - user: ${_currentUser?.username}, role: ${_currentUser?.role}');
    notifyListeners();
  }

  Future<void> _loadTokenFromCache() async {
    final savedToken = CacheHelper.getString(key: 'auth_token');
    log('Checking for cached token: ${savedToken != null ? "found" : "not found"}');
    if (savedToken != null) {
      // Validate token structure before using
      if (JwtHelper.extractExpiry(savedToken) == null) {
        log('Cached token is malformed, clearing');
        await clearUserData();
        return;
      }

      _token = savedToken;
      _api.setToken(_token!);
      log('Token loaded from cache');

      final savedRefreshToken = CacheHelper.getString(key: 'refresh_token');
      if (savedRefreshToken != null) {
        _refreshToken = savedRefreshToken;
        _api.setRefreshToken(_refreshToken!);
        log('Refresh token loaded from cache');
      }

      final savedExpiry = CacheHelper.getInt(key: 'token_expiry');
      if (savedExpiry != null) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(savedExpiry);
        if (_tokenExpiry!.isBefore(DateTime.now())) {
          log('Access token expired, attempting refresh on startup...');
          if (_refreshToken != null) {
            final refreshed = await _attemptRefreshOnStartup();
            if (refreshed) {
              log('Token refreshed successfully on startup');
              await _restoreCachedUser();
              return;
            }
            log('Token refresh failed on startup, clearing all tokens');
          } else {
            log('No refresh token available, clearing tokens');
          }
          await clearUserData();
          return;
        }
        log('Token expiry restored: $_tokenExpiry');
      }

      await _restoreCachedUser();
    } else {
      log('No cached token found');
    }
  }

  Future<void> _restoreCachedUser() async {
    final savedUserData = CacheHelper.getString(key: 'current_user');
    if (savedUserData != null) {
      try {
        final userMap = jsonDecode(savedUserData);
        _currentUser = UserModel.fromJson(userMap);
        log('User data restored from cache: ${_currentUser?.displayName}, role: ${_currentUser?.role}');
        DioClient().scheduleTokenRefresh(_token!);
      } catch (e) {
        log('Failed to parse cached user data: $e');
        await clearUserData();
      }
    } else {
      log('No cached user data found, clearing tokens');
      await clearUserData();
    }
  }

  Future<bool> _attemptRefreshOnStartup() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _api.refreshToken(refreshToken: _refreshToken!);

      final newAccessToken = response['token'] as String?;
      final newRefreshToken = response['refreshToken'] as String?;

      if (newAccessToken == null) return false;

      _token = newAccessToken;
      _api.setToken(newAccessToken);
      await _saveTokenToCache(newAccessToken);

      if (newRefreshToken != null) {
        _refreshToken = newRefreshToken;
        _api.setRefreshToken(newRefreshToken);
        await _saveRefreshTokenToCache(newRefreshToken);
      }

      final exp = JwtHelper.extractExpiry(newAccessToken);
      if (exp != null) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        await CacheHelper.saveData(
            key: 'token_expiry', value: _tokenExpiry!.millisecondsSinceEpoch);
        DioClient().scheduleTokenRefresh(newAccessToken);
      }

      return true;
    } catch (e) {
      log('Refresh on startup failed: $e');
      return false;
    }
  }

  Future<void> _saveTokenToCache(String token) async {
    await CacheHelper.saveData(key: 'auth_token', value: token);
  }

  Future<void> _saveRefreshTokenToCache(String refreshToken) async {
    await CacheHelper.saveData(key: 'refresh_token', value: refreshToken);
  }

  Future<void> _saveUserToCache(UserModel user) async {
    await CacheHelper.saveData(
        key: 'current_user', value: jsonEncode(user.toJson()));
  }

  Future<void> _clearTokenFromCache() async {
    await CacheHelper.removeData(key: 'auth_token');
    await CacheHelper.removeData(key: 'refresh_token');
    await CacheHelper.removeData(key: 'token_expiry');
    await CacheHelper.removeData(key: 'current_user');
  }

  Future<void> refreshAndNotify(String token, UserModel user) async {
    _token = token;
    _currentUser = user;
    _api.setToken(token);
    await _saveTokenToCache(token);
    await _saveUserToCache(user);
    notifyListeners();
  }

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  bool get isUsersLoading => _isUsersLoading;
  bool get isAnyLoading => _isLoading || _isUsersLoading;
  String? get error => _error;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;

  Future<void> clearUserData() async {
    _token = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _currentUser = null;
    _users = [];
    _error = null;
    _api.clearToken();
    _api.clearRefreshToken();
    await _clearTokenFromCache();
    notifyListeners();
  }

  Future<void> updateTokens(String newAccessToken, String newRefreshToken,
      DateTime? newExpiry) async {
    _token = newAccessToken;
    _refreshToken = newRefreshToken;
    _tokenExpiry = newExpiry;
    _api.setToken(newAccessToken);
    _api.setRefreshToken(newRefreshToken);
    await _saveTokenToCache(newAccessToken);
    await _saveRefreshTokenToCache(newRefreshToken);
    if (newExpiry != null) {
      await CacheHelper.saveData(
          key: 'token_expiry', value: newExpiry.millisecondsSinceEpoch);
    }
    if (_currentUser != null) {
      await _saveUserToCache(_currentUser!);
    }
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
      log('SignIn response: $response');
      _token = response['token'];
      _api.setToken(_token!);

      if (response['refreshToken'] != null) {
        _refreshToken = response['refreshToken'];
        _api.setRefreshToken(_refreshToken!);
        await _saveRefreshTokenToCache(_refreshToken!);
      } else {
        log('WARNING: Backend did not return a refreshToken. Auto-refresh will not work.');
      }

      await _saveTokenToCache(_token!);

      final exp = JwtHelper.extractExpiry(_token!);
      if (exp != null) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        await CacheHelper.saveData(
            key: 'token_expiry', value: _tokenExpiry!.millisecondsSinceEpoch);
        log('Token expiry extracted: $_tokenExpiry');
        DioClient().scheduleTokenRefresh(_token!);
      }

      _currentUser = UserModel.fromJson(response);
      await _saveUserToCache(_currentUser!);
      log('Current user set: ${_currentUser?.displayName}, role: ${_currentUser?.role}, department: ${_currentUser?.department}');
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
      await _api.signOut(refreshToken: _refreshToken);
      _api.clearToken();
      _api.clearRefreshToken();
    } catch (e) {
      // Ignore signout API error
    }
    _token = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _currentUser = null;
    _users = [];
    _error = null;
    await _clearTokenFromCache();
    notifyListeners();
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
