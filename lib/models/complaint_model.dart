class ComplaintModel {
  final int? id;
  final String appName;
  final String complaintName;
  final String placeName;
  final String department;
  final String subPlace;
  final String empName;
  final String empNumber;
  final String empMobile;
  final bool isEnable;
  final String? createdAt;

  ComplaintModel({
    this.id,
    required this.appName,
    required this.complaintName,
    required this.placeName,
    required this.department,
    this.subPlace = 'none',
    required this.empName,
    required this.empNumber,
    required this.empMobile,
    this.isEnable = true,
    this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'],
      appName: json['appName'] ?? '',
      complaintName: json['complaintName'] ?? '',
      placeName: json['placeName'] ?? '',
      department: json['department'] ?? '',
      subPlace: json['subPlace'] ?? 'none',
      empName: json['empName'] ?? '',
      empNumber: json['empNumber'] ?? '',
      empMobile: json['empMobile'] ?? '',
      isEnable: json['isEnable'] ?? true,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'complaintName': complaintName,
      'placeName': placeName,
      'department': department,
      'subPlace': subPlace,
      'empName': empName,
      'empNumber': empNumber,
      'empMobile': empMobile,
      'isEnable': isEnable,
    };
  }

  ComplaintModel copyWith({
    int? id,
    String? appName,
    String? complaintName,
    String? placeName,
    String? department,
    String? subPlace,
    String? empName,
    String? empNumber,
    String? empMobile,
    bool? isEnable,
    String? createdAt,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      complaintName: complaintName ?? this.complaintName,
      placeName: placeName ?? this.placeName,
      department: department ?? this.department,
      subPlace: subPlace ?? this.subPlace,
      empName: empName ?? this.empName,
      empNumber: empNumber ?? this.empNumber,
      empMobile: empMobile ?? this.empMobile,
      isEnable: isEnable ?? this.isEnable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
