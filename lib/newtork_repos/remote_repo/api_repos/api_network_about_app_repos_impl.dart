import 'dart:developer';

import '../../../models/about_app_model.dart';
import '../../../models/recommended_item_model.dart';
import 'api_network_about_app_repos.dart';
import 'dio_client.dart';

class ApiNetworkAboutAppReposImpl implements ApiNetworkAboutAppRepos {
  static final ApiNetworkAboutAppReposImpl instance =
      ApiNetworkAboutAppReposImpl._();
  final DioClient _client = DioClient();

  ApiNetworkAboutAppReposImpl._();

  factory ApiNetworkAboutAppReposImpl() => instance;

  @override
  Future<List<AboutApp>> getAllAboutApps() async {
    log('>>> API: Fetching all about apps...');
    final response = await _client.dio.get('/about-apps');
    log('>>> API response: ${response.data}');
    return (response.data as List)
        .map((json) => AboutApp.fromMap(json))
        .toList();
  }

  @override
  Future<List<AboutApp>> getAppsByDepartment(String department) async {
    try {
      final response =
          await _client.dio.get('/about-apps/department/$department');
      return (response.data as List)
          .map((json) => AboutApp.fromMap(json))
          .toList();
    } catch (e) {
      // Fallback - try without department
      final response = await _client.dio.get('/about-apps');
      return (response.data as List)
          .map((json) => AboutApp.fromMap(json))
          .toList();
    }
  }

  @override
  Future<AboutApp> getAboutAppById(int id) async {
    final response = await _client.dio.get('/about-apps/$id');
    return AboutApp.fromMap(response.data);
  }

  @override
  Future<AboutApp> getAboutAppByAppName(String appName) async {
    final response = await _client.dio.get('/about-apps/name/$appName');
    return AboutApp.fromMap(response.data);
  }

  @override
  Future<List<String>> getRecommendedValuesByAppName(String appName) async {
    final response =
        await _client.dio.get('/about-apps/name/$appName/recommended');
    return (response.data as List).map((e) => e.toString()).toList();
  }

  @override
  Future<List<RecommendedItem>> getAllRecommendedByAppName(
      String appName) async {
    final response =
        await _client.dio.get('/about-apps/name/$appName/recommended/all');
    return (response.data as List)
        .map((json) => RecommendedItem.fromMap(json))
        .toList();
  }

  @override
  Future<void> addRecommended(String appName, String recommendedValue) async {
    await _client.dio
        .post('/about-apps/name/$appName/recommended', data: recommendedValue);
  }

  @override
  Future<void> deleteRecommended(int id) async {
    await _client.dio.delete('/about-apps/recommended/$id');
  }

  @override
  Future<AboutApp> addAboutApp(
      String appName, String department, List<String> recommended) async {
    final response = await _client.dio.post('/about-apps', data: {
      'appName': appName,
      'department': department,
      'recommended': recommended,
    });
    return AboutApp.fromMap(response.data);
  }

  @override
  Future<AboutApp> updateAboutApp(int id, String appName, String department,
      List<String> recommended) async {
    final response = await _client.dio.put('/about-apps/$id', data: {
      'appName': appName,
      'department': department,
      'recommended': recommended,
    });
    return AboutApp.fromMap(response.data);
  }

  @override
  Future<void> deleteAboutApp(int id) async {
    await _client.dio.delete('/about-apps/$id');
  }
}
