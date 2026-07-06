class UserModel {
  final int? id;
  final String displayName;
  final String username;
  final String? password;
  final String? role;
  final String? department;
  final bool? enabled;

//Constructor
  UserModel({
    this.id,
    required this.displayName,
    required this.username,
    this.password,
    this.role,
    this.department,
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
    bool? enabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      department: department ?? this.department,
      enabled: enabled ?? this.enabled,
    );
  }
}
