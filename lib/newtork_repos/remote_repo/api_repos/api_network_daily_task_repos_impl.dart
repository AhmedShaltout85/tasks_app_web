import 'dart:developer';
import '../../../models/daily_task_model.dart';
import 'api_network_daily_task_repos.dart';
import 'dio_client.dart';

class ApiNetworkDailyTaskReposImpl implements ApiNetworkDailyTaskRepos {
  static final ApiNetworkDailyTaskReposImpl instance =
      ApiNetworkDailyTaskReposImpl._();
  final DioClient _client = DioClient();

  ApiNetworkDailyTaskReposImpl._();

  factory ApiNetworkDailyTaskReposImpl() => instance;

  @override
  Future<List<DailyTaskModel>> getAllTasks() async {
    log('API: Getting all tasks...');
    final response = await _client.dio.get('/daily-tasks');
    log('API: Got response, data type: ${response.data.runtimeType}');
    final list = (response.data as List)
        .map((json) => DailyTaskModel.fromJson(json))
        .toList();
    log('API: Parsed ${list.length} tasks');
    return list;
  }

  @override
  Future<DailyTaskModel> getTaskById(int id) async {
    final response = await _client.dio.get('/daily-tasks/$id');
    return DailyTaskModel.fromJson(response.data);
  }

  @override
  Future<List<DailyTaskModel>> getTasksAssignedTo(String username) async {
    log('API getTasksAssignedTo: username=$username');
    final response =
        await _client.dio.get('/daily-tasks/assigned-to/$username');
    log('API getTasksAssignedTo response length: ${(response.data as List).length}');
    log('API getTasksAssignedTo response first item isRemote: ${(response.data as List).isNotEmpty ? (response.data as List).first['isRemote'] : 'empty'}');
    return (response.data as List)
        .map((json) => DailyTaskModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<DailyTaskModel>> getTasksAssignedBy(String username) async {
    final response =
        await _client.dio.get('/daily-tasks/assigned-by/$username');
    return (response.data as List)
        .map((json) => DailyTaskModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<DailyTaskModel>> getTasksByAppName(String appName) async {
    final response = await _client.dio.get('/daily-tasks/app/$appName');
    return (response.data as List)
        .map((json) => DailyTaskModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<DailyTaskModel>> getTasksByStatus(bool status) async {
    final response = await _client.dio.get('/daily-tasks/status/$status');
    return (response.data as List)
        .map((json) => DailyTaskModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<DailyTaskModel>> getTasksByPriority(String priority) async {
    final response = await _client.dio.get('/daily-tasks/priority/$priority');
    return (response.data as List)
        .map((json) => DailyTaskModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<DailyTaskModel>> getTasksAssignedToAndIsRemote(
      String username, bool isRemote) async {
    final response = await _client.dio
        .get('/daily-tasks/assigned-to/$username/remote/$isRemote');
    return (response.data as List)
        .map((json) => DailyTaskModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<DailyTaskModel>> getTasksByIsRemote(bool isRemote) async {
    final response = await _client.dio.get('/daily-tasks/remote/$isRemote');
    return (response.data as List)
        .map((json) => DailyTaskModel.fromJson(json))
        .toList();
  }

  @override
  Future<DailyTaskModel> createTask(DailyTaskModel task) async {
    final response =
        await _client.dio.post('/daily-tasks', data: task.toJson());
    return DailyTaskModel.fromJson(response.data);
  }

  @override
  Future<DailyTaskModel> updateTask(int id, DailyTaskModel task) async {
    log('API updateTask: id=$id, isRemote in model: ${task.isRemote}');
    final response =
        await _client.dio.put('/daily-tasks/$id', data: task.toJson());
    log('API updateTask response: ${response.data}');
    return DailyTaskModel.fromJson(response.data);
  }

  @override
  Future<void> deleteTask(int id) async {
    await _client.dio.delete('/daily-tasks/$id');
  }
}
