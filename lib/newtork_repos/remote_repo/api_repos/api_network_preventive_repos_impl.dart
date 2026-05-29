import '../../../models/preventive_item_model.dart';
import '../../../models/preventive_maintenance_model.dart';
import 'api_network_preventive_repos.dart';
import 'dio_client.dart';

class ApiNetworkPreventiveItemReposImpl
    implements ApiNetworkPreventiveItemRepos {
  static final ApiNetworkPreventiveItemReposImpl instance =
      ApiNetworkPreventiveItemReposImpl._();
  final DioClient _client = DioClient();

  ApiNetworkPreventiveItemReposImpl._();

  factory ApiNetworkPreventiveItemReposImpl() => instance;

  // ======================
  // PREVENTIVE ITEM METHODS
  // ======================

  @override
  Future<List<PreventiveItemModel>> getAllPreventiveItemsByDepartment(
      String department) async {
    final response = await _client.dio.get('/preventive-items');
    return (response.data as List)
        .map((json) => PreventiveItemModel.fromJson(json))
        .toList();
  }

  @override
  Future<PreventiveItemModel> getPreventiveItemById(int id) async {
    final response = await _client.dio.get('/preventive-items/$id');
    return PreventiveItemModel.fromJson(response.data);
  }

  @override
  Future<List<PreventiveItemModel>> getPreventiveItemByAppName(
      String appName) async {
    final response = await _client.dio.get('/preventive-items/app/$appName');
    return (response.data as List)
        .map((json) => PreventiveItemModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<String>> getActionsByAppName(String appName) async {
    final response =
        await _client.dio.get('/preventive-items/app/$appName/actions');
    return (response.data as List).map((e) => e.toString()).toList();
  }

  @override
  Future<PreventiveItemModel> addPreventiveItem(
      String appName, String action, String department) async {
    final response = await _client.dio.post('/preventive-items', data: {
      'appName': appName,
      'action': action,
      'department': department,
    });
    return PreventiveItemModel.fromJson(response.data);
  }

  @override
  Future<PreventiveItemModel> updatePreventiveItem(
      int id, String appName, String action, String department) async {
    final response = await _client.dio.put('/preventive-items/$id', data: {
      'appName': appName,
      'action': action,
      'department': department,
    });
    return PreventiveItemModel.fromJson(response.data);
  }

  @override
  Future<void> deletePreventiveItem(int id) async {
    await _client.dio.delete('/preventive-items/$id');
  }

  // ==========================
  // PREVENTIVE MAINTENANCE METHODS
  // ==========================

  @override
  Future<List<PreventiveMaintenanceModel>>
      getAllPreventiveMaintenanceByDepartment(String department) async {
    try {
      final response = await _client.dio.get('/preventive-maintenance');
      return (response.data as List)
          .map((json) => PreventiveMaintenanceModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback - try without department
      final response = await _client.dio.get('/preventive-maintenance');
      return (response.data as List)
          .map((json) => PreventiveMaintenanceModel.fromJson(json))
          .toList();
    }
  }

  @override
  Future<PreventiveMaintenanceModel> getPreventiveMaintenanceById(
      int id) async {
    final response = await _client.dio.get('/preventive-maintenance/$id');
    return PreventiveMaintenanceModel.fromJson(response.data);
  }

  @override
  Future<PreventiveMaintenanceModel> addPreventiveMaintenance({
    required String appName,
    required String action,
    required String username,
    required String placeName,
    String? subPlace,
    bool? isRemote,
    required String department,
  }) async {
    final response = await _client.dio.post('/preventive-maintenance', data: {
      'appName': appName,
      'action': action,
      'username': username,
      'placeName': placeName,
      'subPlace': subPlace,
      'isRemote': isRemote,
      'department': department,
    });
    return PreventiveMaintenanceModel.fromJson(response.data);
  }

  @override
  Future<PreventiveMaintenanceModel> updatePreventiveMaintenance({
    required int id,
    required String appName,
    required String action,
    required String username,
    required String placeName,
    String? subPlace,
    bool? isRemote,
    required String department,
  }) async {
    final response =
        await _client.dio.put('/preventive-maintenance/$id', data: {
      'appName': appName,
      'action': action,
      'username': username,
      'placeName': placeName,
      'subPlace': subPlace,
      'isRemote': isRemote,
      'department': department,
    });
    return PreventiveMaintenanceModel.fromJson(response.data);
  }

  @override
  Future<void> deletePreventiveMaintenance(int id) async {
    await _client.dio.delete('/preventive-maintenance/$id');
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByAppName(
      String appName) async {
    final response =
        await _client.dio.get('/preventive-maintenance/app/$appName');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByUsername(
      String username) async {
    final response =
        await _client.dio.get('/preventive-maintenance/user/$username');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByPlaceName(
      String placeName) async {
    final response =
        await _client.dio.get('/preventive-maintenance/place/$placeName');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceBySubPlace(
      String subPlace) async {
    final response =
        await _client.dio.get('/preventive-maintenance/sub-place/$subPlace');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByIsRemote(
      bool isRemote) async {
    final response =
        await _client.dio.get('/preventive-maintenance/remote/$isRemote');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByAppNameAndUsername(
      String appName, String username) async {
    final response = await _client.dio
        .get('/preventive-maintenance/app/$appName/user/$username');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByAppNameAndPlaceName(
      String appName, String placeName) async {
    final response = await _client.dio
        .get('/preventive-maintenance/app/$appName/place/$placeName');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByUsernameAndPlaceName(
      String username, String placeName) async {
    final response = await _client.dio
        .get('/preventive-maintenance/user/$username/place/$placeName');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByAppNameAndIsRemote(
      String appName, bool isRemote) async {
    final response = await _client.dio
        .get('/preventive-maintenance/app/$appName/remote/$isRemote');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByUsernameAndIsRemote(
      String username, bool isRemote) async {
    final response = await _client.dio
        .get('/preventive-maintenance/user/$username/remote/$isRemote');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByPlaceNameAndIsRemote(
      String placeName, bool isRemote) async {
    final response = await _client.dio
        .get('/preventive-maintenance/place/$placeName/remote/$isRemote');
    return (response.data as List)
        .map((json) => PreventiveMaintenanceModel.fromJson(json))
        .toList();
  }
}
