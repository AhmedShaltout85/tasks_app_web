import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../models/complaint_model.dart';
import '../newtork_repos/remote_repo/api_repos/api_network_complaint_repos_impl.dart';

class ComplaintProvider with ChangeNotifier {
  final ApiNetworkComplaintReposImpl _api = ApiNetworkComplaintReposImpl();

  List<ComplaintModel> _complaints = [];
  List<ComplaintModel> _filteredComplaints = [];
  bool _isLoading = false;
  String? _error;
  String? _currentFilterApp;
  String? _currentFilterDept;
  String? _currentFilterEmp;

  List<ComplaintModel> get complaints =>
      _filteredComplaints.isNotEmpty || _currentFilterApp != null || _currentFilterDept != null || _currentFilterEmp != null
          ? _filteredComplaints
          : _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllComplaints() async {
    _setLoading(true);
    try {
      _complaints = await _api.getAllComplaints();
      _error = null;
      _clearLocalFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchByDepartmentAndIsEnable(
      String department, bool isEnable) async {
    log('>>> Provider: fetchByDepartmentAndIsEnable called');
    _setLoading(true);
    try {
      _complaints =
          await _api.getByDepartmentAndIsEnable(department, isEnable);
      _error = null;
      _clearLocalFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addComplaint(ComplaintModel complaint) async {
    _setLoading(true);
    try {
      final newComplaint = await _api.createComplaint(complaint);
      _complaints.add(newComplaint);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateComplaint(int id, ComplaintModel complaint) async {
    _setLoading(true);
    try {
      final updated = await _api.updateComplaint(id, complaint);
      final index = _complaints.indexWhere((c) => c.id == id);
      if (index != -1) {
        _complaints[index] = updated;
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

  Future<void> deleteComplaint(int id) async {
    _setLoading(true);
    try {
      await _api.deleteComplaint(id);
      _complaints.removeWhere((c) => c.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Local filter methods
  List<String> getUniqueAppNames() {
    return _complaints.map((c) => c.appName).toSet().toList();
  }

  List<String> getUniqueDepartments() {
    return _complaints.map((c) => c.department).toSet().toList();
  }

  List<String> getUniqueEmpNames() {
    return _complaints.map((c) => c.empName).toSet().toList();
  }

  void filterByAppName(String appName) {
    _currentFilterDept = null;
    _currentFilterEmp = null;
    if (appName == 'الكل') {
      _currentFilterApp = null;
      _filteredComplaints = [];
    } else {
      _currentFilterApp = appName;
      _filteredComplaints =
          _complaints.where((c) => c.appName == appName).toList();
    }
    notifyListeners();
  }

  void filterByDepartment(String department) {
    _currentFilterApp = null;
    _currentFilterEmp = null;
    if (department == 'الكل') {
      _currentFilterDept = null;
      _filteredComplaints = [];
    } else {
      _currentFilterDept = department;
      _filteredComplaints =
          _complaints.where((c) => c.department == department).toList();
    }
    notifyListeners();
  }

  void filterByEmpName(String empName) {
    _currentFilterApp = null;
    _currentFilterDept = null;
    if (empName == 'الكل') {
      _currentFilterEmp = null;
      _filteredComplaints = [];
    } else {
      _currentFilterEmp = empName;
      _filteredComplaints =
          _complaints.where((c) => c.empName == empName).toList();
    }
    notifyListeners();
  }

  void clearFilter() {
    _clearLocalFilters();
    notifyListeners();
  }

  void _clearLocalFilters() {
    _currentFilterApp = null;
    _currentFilterDept = null;
    _currentFilterEmp = null;
    _filteredComplaints = [];
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
