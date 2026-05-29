import 'dart:developer';
import 'package:flutter/foundation.dart';

import '../models/daily_task_model.dart';
import '../newtork_repos/remote_repo/api_repos/api_network_daily_task_repos_impl.dart';

class DailyTaskProvider with ChangeNotifier {
  final ApiNetworkDailyTaskReposImpl _api = ApiNetworkDailyTaskReposImpl();

  List<DailyTaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<DailyTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllTasks() async {
    
    _setLoading(true);
    try {
      log('DailyTaskProvider: Fetching all tasks...');
      _tasks = await _api.getAllTasks();
      log('DailyTaskProvider: Fetched ${_tasks.length} tasks');
      _error = null;
      notifyListeners();
    } catch (e) {
      log('DailyTaskProvider: Error: $e');
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTaskById(int id) async {
    _setLoading(true);
    try {
      final task = await _api.getTaskById(id);
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = task;
      } else {
        _tasks.add(task);
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTasksAssignedTo(String username) async {
    _setLoading(true);
    log('DailyTaskProvider: fetchTasksAssignedTo($username)');
    try {
      _tasks = await _api.getTasksAssignedTo(username);
      log('DailyTaskProvider: Got ${_tasks.length} tasks. First task isRemote: ${_tasks.isNotEmpty ? _tasks.first.isRemote : "none"}');
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTasksAssignedBy(String username) async {
    _setLoading(true);
    try {
      _tasks = await _api.getTasksAssignedBy(username);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTasksByAppName(String appName) async {
    _setLoading(true);
    try {
      _tasks = await _api.getTasksByAppName(appName);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTasksByStatus(bool status) async {
    _setLoading(true);
    try {
      _tasks = await _api.getTasksByStatus(status);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTasksByPriority(String priority) async {
    _setLoading(true);
    try {
      _tasks = await _api.getTasksByPriority(priority);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTasksAssignedToAndIsRemote(
      String username, bool isRemote) async {
    _setLoading(true);
    try {
      _tasks = await _api.getTasksAssignedToAndIsRemote(username, isRemote);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTasksByIsRemote(bool isRemote) async {
    _setLoading(true);
    try {
      _tasks = await _api.getTasksByIsRemote(isRemote);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createTask(DailyTaskModel task) async {
    _setLoading(true);
    try {
      final newTask = await _api.createTask(task);
      _tasks.add(newTask);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTask(int id, DailyTaskModel task) async {
    _setLoading(true);
    try {
      final updatedTask = await _api.updateTask(id, task);
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTask(int id) async {
    _setLoading(true);
    try {
      await _api.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
