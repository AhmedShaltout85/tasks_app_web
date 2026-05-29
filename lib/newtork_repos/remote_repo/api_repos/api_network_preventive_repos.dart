import '../../../models/preventive_item_model.dart';
import '../../../models/preventive_maintenance_model.dart';

abstract class ApiNetworkPreventiveItemRepos {
  // Preventive Item endpoints
  Future<List<PreventiveItemModel>> getAllPreventiveItemsByDepartment(
      String department);

  Future<PreventiveItemModel> getPreventiveItemById(int id);

  Future<List<PreventiveItemModel>> getPreventiveItemByAppName(String appName);

  Future<List<String>> getActionsByAppName(String appName);

  Future<PreventiveItemModel> addPreventiveItem(
      String appName, String action, String department);

  Future<PreventiveItemModel> updatePreventiveItem(
      int id, String appName, String action, String department);

  Future<void> deletePreventiveItem(int id);

  // Preventive Maintenance endpoints
  Future<List<PreventiveMaintenanceModel>>
      getAllPreventiveMaintenanceByDepartment(String department);

  Future<PreventiveMaintenanceModel> getPreventiveMaintenanceById(int id);

  Future<PreventiveMaintenanceModel> addPreventiveMaintenance({
    required String appName,
    required String action,
    required String username,
    required String placeName,
    String? subPlace,
    bool? isRemote,
    required String department,
  });

  Future<PreventiveMaintenanceModel> updatePreventiveMaintenance({
    required int id,
    required String appName,
    required String action,
    required String username,
    required String placeName,
    String? subPlace,
    bool? isRemote,
    required String department,
  });

  Future<void> deletePreventiveMaintenance(int id);

  // Get by various filters
  Future<List<PreventiveMaintenanceModel>> getMaintenanceByAppName(
      String appName);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceByUsername(
      String username);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceByPlaceName(
      String placeName);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceBySubPlace(
      String subPlace);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceByIsRemote(
      bool isRemote);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceByAppNameAndUsername(
      String appName, String username);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceByAppNameAndPlaceName(
      String appName, String placeName);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceByUsernameAndPlaceName(
      String username, String placeName);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceByAppNameAndIsRemote(
      String appName, bool isRemote);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceByUsernameAndIsRemote(
      String username, bool isRemote);

  Future<List<PreventiveMaintenanceModel>> getMaintenanceByPlaceNameAndIsRemote(
      String placeName, bool isRemote);
}
