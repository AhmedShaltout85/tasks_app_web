import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../models/complaint_model.dart';
import 'api_network_complaint_repos.dart';

class ComplaintDioClient {
  static final ComplaintDioClient instance = ComplaintDioClient._();
  factory ComplaintDioClient() => instance;

  late final Dio _dio;

  ComplaintDioClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://41.33.226.211:8099/tasks-complaint-emp',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  Dio get dio => _dio;
}

class ApiNetworkComplaintReposImpl implements ApiNetworkComplaintRepos {
  static final ApiNetworkComplaintReposImpl instance =
      ApiNetworkComplaintReposImpl._();
  final ComplaintDioClient _client = ComplaintDioClient();

  ApiNetworkComplaintReposImpl._();

  factory ApiNetworkComplaintReposImpl() => instance;

  @override
  Future<List<ComplaintModel>> getAllComplaints() async {
    log('>>> API: Fetching all complaints...');
    final response = await _client.dio.get('/api/emp-complaints');
    return (response.data as List)
        .map((json) => ComplaintModel.fromJson(json))
        .toList();
  }

  @override
  Future<ComplaintModel> getComplaintById(int id) async {
    final response = await _client.dio.get('/api/emp-complaints/$id');
    return ComplaintModel.fromJson(response.data);
  }

  @override
  Future<List<ComplaintModel>> getByDepartment(String department) async {
    final response =
        await _client.dio.get('/api/emp-complaints/department/$department');
    return (response.data as List)
        .map((json) => ComplaintModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ComplaintModel>> getByIsEnable(bool isEnable) async {
    final response =
        await _client.dio.get('/api/emp-complaints/enable/$isEnable');
    return (response.data as List)
        .map((json) => ComplaintModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ComplaintModel>> getByDepartmentAndIsEnable(
      String department, bool isEnable) async {
    log('>>> API: Fetching complaints by department=$department, isEnable=$isEnable');
    final response = await _client.dio
        .get('/api/emp-complaints/department/$department/enable/$isEnable');
    return (response.data as List)
        .map((json) => ComplaintModel.fromJson(json))
        .toList();
  }

  @override
  Future<ComplaintModel> createComplaint(ComplaintModel complaint) async {
    final response = await _client.dio
        .post('/api/emp-complaints', data: complaint.toJson());
    return ComplaintModel.fromJson(response.data);
  }

  @override
  Future<ComplaintModel> updateComplaint(
      int id, ComplaintModel complaint) async {
    final response = await _client.dio
        .put('/api/emp-complaints/$id', data: complaint.toJson());
    return ComplaintModel.fromJson(response.data);
  }

  @override
  Future<void> deleteComplaint(int id) async {
    await _client.dio.delete('/api/emp-complaints/$id');
  }
}
