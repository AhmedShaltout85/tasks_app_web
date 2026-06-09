import 'dart:developer';

import '../../../models/user_model.dart';
import 'api_network_user_repos.dart';
import 'dio_client.dart';

class ApiNetworkUserReposImpl implements ApiNetworkUserRepos {
  static final ApiNetworkUserReposImpl instance = ApiNetworkUserReposImpl._();
  final DioClient _client = DioClient();

  ApiNetworkUserReposImpl._();

  factory ApiNetworkUserReposImpl() => instance;

  void setToken(String token) => _client.setToken(token);

  void clearToken() => _client.clearToken();

  void setRefreshToken(String refreshToken) =>
      _client.setRefreshToken(refreshToken);

  void clearRefreshToken() => _client.clearRefreshToken();

  @override
  Future<Map<String, dynamic>> signUp({
    required String displayName,
    required String username,
    required String password,
    required String role,
    required String department,
  }) async {
    final response = await _client.dio.post('/auth/signup', data: {
      'displayName': displayName,
      'username': username,
      'password': password,
      'role': role,
      'department': department,
    });
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
  }) async {
    final response = await _client.dio.post('/auth/signin', data: {
      'username': username,
      'password': password,
    });
    if (response.data['token'] != null) {
      log("TOKEN ===>" + response.data['token']);
      log("REFRESH_TOKEN ===>" + response.data['refreshToken']);

      _client.setToken(response.data['token']);
    }
    return response.data;
  }

  @override
  Future<void> signOut({String? refreshToken}) async {
    await _client.dio.post('/auth/signout', data: {
      if (refreshToken != null) 'refreshToken': refreshToken,
    });
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final response = await _client.dio.get('/users');
    return (response.data as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  @override
  Future<UserModel> getUserById(int id) async {
    final response = await _client.dio.get('/users/$id');
    return UserModel.fromJson(response.data);
  }

  @override
  Future<List<UserModel>> getUsersByDepartment(String department) async {
    final response = await _client.dio.get('/users/department/$department/all');
    return (response.data as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<UserModel>> getUsersByRole(String role) async {
    final response = await _client.dio.get('/users/role/$role');
    return (response.data as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<UserModel>> getEnabledUsersByRole(
      String role, bool enabled) async {
    final response =
        await _client.dio.get('/users/role/$role/enabled/$enabled');
    return (response.data as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> setUserEnabled(int id, bool enabled) async {
    await _client.dio.put('/users/$id/enable?enabled=$enabled');
    // no parsing — backend returns partial object without id
  }

  @override
  Future<void> deleteUser(int id) async {
    await _client.dio.delete('/users/$id');
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.put('/users/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  @override
  Future<Map<String, dynamic>> refreshToken(
      {required String refreshToken}) async {
    final response =
        await _client.dioForRefresh.post('/auth/refresh-token', data: {
      'refreshToken': refreshToken,
    });
    return response.data;
  }

  @override
  Future<void> forgotPassword({
    required String username,
    required String newPassword,
  }) async {
    await _client.dio.post('/auth/forgot-password', data: {
      'username': username,
      'newPassword': newPassword,
    });
  }
}
