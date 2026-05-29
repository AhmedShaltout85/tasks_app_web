class PreventiveMaintenanceModel {
  final int? id;
  final String appName;
  final String placeName;
  final String? subPlace;
  final bool isRemote;
  final String username;
  final String action;
  final String department;
  final DateTime? createdAt;

  // Constructor
  PreventiveMaintenanceModel({
    this.id,
    required this.appName,
    required this.placeName,
    this.subPlace,
    this.isRemote = false,
    required this.username,
    required this.action,
    required this.department,
    this.createdAt,
  });

  // From JSON method
  factory PreventiveMaintenanceModel.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['createdAt'];
    DateTime? parsedDate;
    if (createdAtStr != null) {
      parsedDate = DateTime.tryParse(createdAtStr.toString());
    }
    return PreventiveMaintenanceModel(
      id: json['id'] as int?,
      appName: json['appName'] as String? ?? '',
      placeName: json['placeName'] as String? ?? '',
      subPlace: json['subPlace'] as String? ?? '',
      isRemote: json['isRemote'] as bool? ?? false,
      username: json['username'] as String? ?? '',
      action: json['action'] as String? ?? '',
      department: json['department'] as String? ?? '',
      createdAt: parsedDate,
    );
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'placeName': placeName,
      'subPlace': subPlace,
      'isRemote': isRemote,
      'username': username,
      'action': action,
      'department': department,
    };
  }

  // Copy with method
  PreventiveMaintenanceModel copyWith({
    int? id,
    String? appName,
    String? placeName,
    String? subPlace,
    bool? isRemote,
    String? username,
    String? action,
    String? department,
  }) {
    return PreventiveMaintenanceModel(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      placeName: placeName ?? this.placeName,
      subPlace: subPlace ?? this.subPlace,
      isRemote: isRemote ?? this.isRemote,
      username: username ?? this.username,
      action: action ?? this.action,
      department: department ?? this.department,
    );
  }
}
