import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../newtork_repos/remote_repo/api_repos/api_network_user_repos_impl.dart';
import '../newtork_repos/remote_repo/api_repos/dio_client.dart';
import 'local_control/cache_helper.dart';

class UserProvider with ChangeNotifier {
  final ApiNetworkUserReposImpl _api = ApiNetworkUserReposImpl();

  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isUsersLoading = false;
  String? _error;
  String? _token;

  UserProvider() {
    _setupCallbacks();
    _init();
  }

  void _setupCallbacks() {
    final dioClient = DioClient();
    dioClient.setCallbacks(
      credentialsGetter: getSavedCredentials,
      onTokenRefreshed: (newToken, userData) async {
        _token = newToken;
        _currentUser = UserModel.fromJson(userData);
        await _saveTokenToCache(newToken);
        await _saveUserToCache(_currentUser!);
        notifyListeners();
      },
      onReLoginFailed: () {
        clearUserData();
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
    final savedToken = CacheHelper.getData(key: 'auth_token');
    log('Checking for cached token: ${savedToken != null ? "found" : "not found"}');
    if (savedToken != null) {
      _token = savedToken as String;
      _api.setToken(_token!);
      log('Token loaded from cache');

      final savedUserData = CacheHelper.getData(key: 'current_user');
      if (savedUserData != null) {
        try {
          final userMap = jsonDecode(savedUserData as String);
          _currentUser = UserModel.fromJson(userMap);
          log('User data restored from cache: ${_currentUser?.displayName}, role: ${_currentUser?.role}');
        } catch (e) {
          log('Failed to parse cached user data: $e');
          _token = null;
          _api.clearToken();
          await _clearTokenFromCache();
        }
      } else {
        _token = null;
        _api.clearToken();
        await _clearTokenFromCache();
        log('No cached user data found, cleared token');
      }
    } else {
      log('No cached token found');
    }
  }

  Future<void> _saveTokenToCache(String token) async {
    await CacheHelper.saveData(key: 'auth_token', value: token);
  }

  Future<void> _saveUserToCache(UserModel user) async {
    await CacheHelper.saveData(
        key: 'current_user', value: jsonEncode(user.toJson()));
  }

  Future<void> _saveCredentialsToCache(String username, String password) async {
    await CacheHelper.saveData(key: 'saved_username', value: username);
    await CacheHelper.saveData(key: 'saved_password', value: password);
  }

  Future<void> _clearTokenFromCache() async {
    await CacheHelper.removeData(key: 'auth_token');
    await CacheHelper.removeData(key: 'current_user');
    await CacheHelper.removeData(key: 'saved_username');
    await CacheHelper.removeData(key: 'saved_password');
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final username = CacheHelper.getData(key: 'saved_username');
    final password = CacheHelper.getData(key: 'saved_password');
    if (username != null && password != null) {
      return {'username': username as String, 'password': password as String};
    }
    return null;
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
  bool get isLoading => _isLoading; // For login/signup operations
  bool get isUsersLoading => _isUsersLoading; // For fetching user lists
  bool get isAnyLoading =>
      _isLoading || _isUsersLoading; // Combined for AuthWrapper
  String? get error => _error;
  String? get token => _token;

  void clearUserData() async {
    _token = null;
    _currentUser = null;
    _users = [];
    _error = null;
    _api.clearToken();
    await _clearTokenFromCache();
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
      final response = await _api.signUp(
        displayName: displayName,
        username: username,
        password: password,
        role: role,
        department: department,
      );
      if (response['token'] != null) {
        _token = response['token'];
        _api.setToken(_token!);
      }
      _error = null;
      // notifyListeners();
    } catch (e) {
      _error = e.toString();
      // notifyListeners();
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
      await _saveTokenToCache(_token!);
      _currentUser = UserModel.fromJson(response);
      await _saveUserToCache(_currentUser!);
      await _saveCredentialsToCache(username, password);
      log('Current user set: ${_currentUser?.displayName}, role: ${_currentUser?.role}, department: ${_currentUser?.department}');
      _error = null;
      // notifyListeners();
    } on DioException catch (e) {
      log('SignIn error: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        final data = e.response?.data;
        _error = data['error'] ?? 'Invalid username or password';
      } else {
        _error = e.message ?? 'Login failed';
      }
      // notifyListeners();
    } catch (e) {
      log('SignIn error: $e');
      _error = e.toString();
      // notifyListeners();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _api.signOut();
      _api.clearToken();
    } catch (e) {
      // Ignore signout API error
    }
    _token = null;
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
      // notifyListeners();
    } catch (e) {
      _error = e.toString();
      // notifyListeners();
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
      // notifyListeners();
    } catch (e) {
      _error = e.toString();
      // notifyListeners();
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
      // notifyListeners();
    } catch (e) {
      _error = e.toString();
      // notifyListeners();
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
      // notifyListeners();
    } catch (e) {
      _error = e.toString();
      // notifyListeners();
    } finally {
      notifyListeners();

      _setUsersLoading(false);
    }
  }

  Future<void> fetchEnabledUsersByRole(String role, bool enabled) async {
    log('fetchEnabledUsersByRole called - role: $role, enabled: $enabled');

    _isUsersLoading = true; // set directly, no notify
    notifyListeners(); // single notify for loading start

    try {
      _users = await _api.getEnabledUsersByRole(role, enabled);
      log('Users fetched successfully: ${_users.length}');
      _error = null;
    } catch (e) {
      log('Error fetching users: $e');
      _error = e.toString();
    } finally {
      _isUsersLoading = false; // set directly, no notify
      notifyListeners(); // single notify for everything at the end
    }
  }

  Future<void> setUserEnabled(int id, bool enabled) async {
    log('setUserEnabled called - id: $id, enabled: $enabled');

    _isLoading = true;
    notifyListeners();

    try {
      await _api.setUserEnabled(id, enabled); // don't parse response

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
      // notifyListeners();
    } catch (e) {
      _error = e.toString();
      // notifyListeners();
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
      // notifyListeners();
    } catch (e) {
      _error = e.toString();
      // notifyListeners();
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
      // notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 400) {
        final data = e.response?.data;
        _error = data['error'] ?? data['message'] ?? 'User not found';
      } else {
        _error = e.message ?? 'Failed to reset password';
      }
      // notifyListeners();
    } catch (e) {
      _error = e.toString();
      // notifyListeners();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    // notifyListeners();
  }

  void _setUsersLoading(bool value) {
    _isUsersLoading = value;
    // notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
