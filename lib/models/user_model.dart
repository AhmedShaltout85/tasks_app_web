class UserModel {
  final int? id;
  final String displayName;
  final String username;
  final String? password;
  final String? role;
  final String? department;
  final String? token;
  final bool? enabled;

//Constructor
  UserModel({
    this.id,
    required this.displayName,
    required this.username,
    this.password,
    this.role,
    this.department,
    this.token,
    this.enabled,
  });

//FromJson
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as int?) ?? 0,
      displayName: json['displayName'] ?? '',
      username: json['username'] ?? '',
      password: json['password'],
      role: json['role'],
      department: json['department'],
      token: json['token'],
      enabled: json['enabled'],
    );
  }
  //ToJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'password': password,
      'role': role,
      'department': department,
      'token': token,
      'enabled': enabled,
    };
  }

  //CopyWith
  UserModel copyWith({
    int? id,
    String? displayName,
    String? username,
    String? password,
    String? role,
    String? department,
    String? token,
    bool? enabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      department: department ?? this.department,
      token: token ?? this.token,
      enabled: enabled ?? this.enabled,
    );
  }
}
