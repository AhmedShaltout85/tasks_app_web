class DailyTaskModel {
  //Properties
  final int? id;
  final String taskTitle;
  final bool taskStatus;
  final String appName;
  final String visitPlace;
  final String subPlace;
  final String assignedTo;
  final String assignedBy;
  final List<dynamic> coOperator;
  final DateTime expectedCompletionDate;
  final String taskPriority;
  final String? taskNote;
  final bool? isRemote;
  final DateTime createdAt;

  //Constructor
  DailyTaskModel({
    this.id,
    required this.taskTitle,
    required this.taskStatus,
    required this.appName,
    required this.visitPlace,
    required this.subPlace,
    required this.assignedTo,
    required this.assignedBy,
    required this.coOperator,
    required this.expectedCompletionDate,
    required this.taskPriority,
    this.taskNote = 'none',
    this.isRemote = false,
    required this.createdAt,
  });

  //fromJson
  factory DailyTaskModel.fromJson(Map<String, dynamic> json) {
    return DailyTaskModel(
      id: json['id'] as int,
      taskTitle: json['taskTitle'] ?? '',
      taskStatus: json['taskStatus'] ?? false,
      appName: json['appName'] ?? '',
      visitPlace: json['visitPlace'] ?? '',
      subPlace: json['subPlace'] ?? '',
      assignedTo: json['assignedTo'] ?? '',
      assignedBy: json['assignedBy'] ?? '',
      coOperator: json['coOperator'] ?? [],
      expectedCompletionDate: json['expectedCompletionDate'] != null
          ? DateTime.parse(json['expectedCompletionDate'])
          : DateTime.now(),
      taskPriority: json['taskPriority'] ?? 'MEDIUM',
      taskNote: json['taskNote'],
      isRemote: json['isRemote'] == true || json['remote'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  //toJson
  Map<String, dynamic> toJson() {
    return {
      'taskTitle': taskTitle,
      'taskStatus': taskStatus,
      'appName': appName,
      'visitPlace': visitPlace,
      'subPlace': subPlace,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'coOperator': coOperator,
      'expectedCompletionDate': expectedCompletionDate.toIso8601String(),
      'taskPriority': taskPriority,
      'taskNote': taskNote,
      'isRemote': isRemote,
    };
  }

  //copyWith
  DailyTaskModel copyWith({
    int? id,
    String? taskTitle,
    bool? taskStatus,
    String? appName,
    String? visitPlace,
    String? subPlace,
    String? assignedTo,
    String? assignedBy,
    List<dynamic>? coOperator,
    DateTime? expectedCompletionDate,
    String? taskPriority,
    String? taskNote,
    bool? isRemote,
    DateTime? createdAt,
  }) {
    return DailyTaskModel(
      id: id ?? this.id,
      taskTitle: taskTitle ?? this.taskTitle,
      taskStatus: taskStatus ?? this.taskStatus,
      appName: appName ?? this.appName,
      visitPlace: visitPlace ?? this.visitPlace,
      subPlace: subPlace ?? this.subPlace,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
      coOperator: coOperator ?? this.coOperator,
      expectedCompletionDate:
          expectedCompletionDate ?? this.expectedCompletionDate,
      taskPriority: taskPriority ?? this.taskPriority,
      taskNote: taskNote ?? this.taskNote,
      isRemote: isRemote ?? this.isRemote,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
