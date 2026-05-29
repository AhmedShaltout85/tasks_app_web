import '../../../models/daily_task_model.dart';

abstract class ApiNetworkDailyTaskRepos {
  Future<List<DailyTaskModel>> getAllTasks();

  Future<DailyTaskModel> getTaskById(int id);

  Future<List<DailyTaskModel>> getTasksAssignedTo(String username);

  Future<List<DailyTaskModel>> getTasksAssignedBy(String username);

  Future<List<DailyTaskModel>> getTasksByAppName(String appName);

  Future<List<DailyTaskModel>> getTasksByStatus(bool status);

  Future<List<DailyTaskModel>> getTasksByPriority(String priority);

  Future<List<DailyTaskModel>> getTasksAssignedToAndIsRemote(
      String username, bool isRemote);

  Future<List<DailyTaskModel>> getTasksByIsRemote(bool isRemote);

  Future<DailyTaskModel> createTask(DailyTaskModel task);

  Future<DailyTaskModel> updateTask(int id, DailyTaskModel task);

  Future<void> deleteTask(int id);
}
