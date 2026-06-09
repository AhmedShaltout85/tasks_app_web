import '../../../models/user_model.dart';

abstract class ApiNetworkUserRepos {
  Future<Map<String, dynamic>> signUp({
    required String displayName,
    required String username,
    required String password,
    required String role,
    required String department,
  });

  Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
  });

  Future<void> signOut({String? refreshToken});

  Future<Map<String, dynamic>> refreshToken({required String refreshToken});

  Future<List<UserModel>> getAllUsers();

  Future<UserModel> getUserById(int id);

  Future<List<UserModel>> getUsersByDepartment(String department);

  Future<List<UserModel>> getUsersByRole(String role);

  Future<List<UserModel>> getEnabledUsersByRole(String role, bool enabled);

  Future<void> setUserEnabled(int id, bool enabled);
  // Future<UserModel> setUserEnabled(int id, bool enabled);

  Future<void> deleteUser(int id);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> forgotPassword({
    required String username,
    required String newPassword,
  });
}
