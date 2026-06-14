import '../../../models/complaint_model.dart';

abstract class ApiNetworkComplaintRepos {
  Future<List<ComplaintModel>> getAllComplaints();

  Future<ComplaintModel> getComplaintById(int id);

  Future<List<ComplaintModel>> getByDepartment(String department);

  Future<List<ComplaintModel>> getByIsEnable(bool isEnable);

  Future<List<ComplaintModel>> getByDepartmentAndIsEnable(
      String department, bool isEnable);

  Future<ComplaintModel> createComplaint(ComplaintModel complaint);

  Future<ComplaintModel> updateComplaint(int id, ComplaintModel complaint);

  Future<void> deleteComplaint(int id);
}
