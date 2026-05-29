class AboutApp {
  final int? id;
  final String appName;
  final String department;
  final List<String> recommended;

  AboutApp({
    this.id,
    required this.appName,
    required this.department,
    required this.recommended,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'department': department,
      'recommended': recommended,
    };
  }

  factory AboutApp.fromMap(Map<String, dynamic> map) {
    return AboutApp(
      id: map['id'],
      appName: map['appName'] ?? '',
      department: map['department'] ?? '',
      recommended: _parseRecommended(map['recommended']),
    );
  }

  AboutApp copyWith({
    int? id,
    String? appName,
    String? department,
    List<String>? recommended,
  }) {
    return AboutApp(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      department: department ?? this.department,
      recommended: recommended ?? this.recommended,
    );
  }

  static List<String> _parseRecommended(dynamic value) {
    if (value == null || value == '') return [];
    if (value is List) return List<String>.from(value);
    if (value is String) return [value];
    return [];
  }
}
