class PreventiveItemModel {
  final int? id;
  final String appName;
  final String action;
  final String department;
  //Constructor
  PreventiveItemModel({
    this.id,
    required this.appName,
    required this.action,
    required this.department,
  });
//fromJson
  factory PreventiveItemModel.fromJson(Map<String, dynamic> json) {
    return PreventiveItemModel(
      id: json['id'] as int?,
      appName: json['appName'],
      action: json['action'],
      department: json['department'] as String? ?? '',
    );
  }

//toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'action': action,
      'department': department,
    };
  }

//copyWith
  PreventiveItemModel copyWith({
    int? id,
    String? appName,
    String? action,
    String? department,
  }) {
    return PreventiveItemModel(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      action: action ?? this.action,
      department: department ?? this.department,
    );
  }
}
