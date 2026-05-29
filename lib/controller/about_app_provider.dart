import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../models/about_app_model.dart';
import '../models/recommended_item_model.dart';
import '../newtork_repos/remote_repo/api_repos/api_network_about_app_repos_impl.dart';

class AboutAppProvider with ChangeNotifier {
  final ApiNetworkAboutAppReposImpl _api = ApiNetworkAboutAppReposImpl();

  List<AboutApp> _aboutApps = [];
  bool _isLoading = false;
  String? _error;
   bool _isAdmin = false; // Change from _isUser to _isAdmin

  List<AboutApp> get aboutApps => _aboutApps;
  bool get isLoading => _isLoading;
  String? get error => _error;


  bool get isAdmin => _isAdmin; // Change getter to isAdmin

  // Modified to set admin status
  void setUserRole(String? role, {bool shouldNotify = true}) {
    final newIsAdmin = role != 'USER'; // ADMIN or MANAGER = true, USER = false
    if (_isAdmin != newIsAdmin) {
      _isAdmin = newIsAdmin;
      if (shouldNotify) {
        notifyListeners();
      }
    }
  }

  Future<void> fetchAllAboutApps() async {
    log('>>> Provider: fetchAllAboutApps called');
    _setLoading(true);
    try {
      _aboutApps = await _api.getAllAboutApps();
      log('>>> Provider: Got ${_aboutApps.length} about apps');
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAppsByDepartment(String department) async {
    _setLoading(true);
    try {
      _aboutApps = await _api.getAppsByDepartment(department);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<String>> fetchRecommendedByAppName(String appName) async {
    log('>>> Provider: fetchRecommendedByAppName called for: $appName');
    _setLoading(true);
    try {
      final recommended = await _api.getRecommendedValuesByAppName(appName);
      _error = null;
      notifyListeners();
      return recommended;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<List<RecommendedItem>> fetchAllRecommendedByAppName(
      String appName) async {
    log('>>> Provider: fetchAllRecommendedByAppName called for: $appName');
    _setLoading(true);
    try {
      final recommended = await _api.getAllRecommendedByAppName(appName);
      _error = null;
      notifyListeners();
      return recommended;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addRecommended(String appName, String recommendedValue) async {
    _setLoading(true);
    try {
      await _api.addRecommended(appName, recommendedValue);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteRecommended(int id) async {
    _setLoading(true);
    try {
      await _api.deleteRecommended(id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAboutApp(
      String appName, String department, List<String>? recommended) async {
    _setLoading(true);
    try {
      final newApp =
          await _api.addAboutApp(appName, department, recommended ?? []);
      _aboutApps.add(newApp);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAboutApp(int id, String appName, String department,
      List<String>? recommended) async {
    _setLoading(true);
    try {
      final updatedApp =
          await _api.updateAboutApp(id, appName, department, recommended ?? []);
      final index = _aboutApps.indexWhere((a) => a.id == id);
      if (index != -1) {
        _aboutApps[index] = updatedApp;
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

  Future<void> deleteAboutApp(int id) async {
    _setLoading(true);
    try {
      await _api.deleteAboutApp(id);
      _aboutApps.removeWhere((a) => a.id == id);
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
