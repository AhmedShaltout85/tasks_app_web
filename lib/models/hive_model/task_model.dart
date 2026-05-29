// lib/models/task_model.dart
import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? title;

  @HiveField(2)
  final bool status;

  @HiveField(3)
  final String? taskDescription;

  @HiveField(4)
  final String? assignedTo;

  @HiveField(5)
  final DateTime? createdAt;

  @HiveField(6)
  final DateTime? updatedAt;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final bool isSynced;

  @HiveField(9)
  final bool isDeleted;

  TaskModel({
    required this.id,
    this.title,
    required this.status,
    this.taskDescription,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.isSynced = false,
    this.isDeleted = false,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    bool? status,
    String? taskDescription,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      taskDescription: taskDescription ?? this.taskDescription,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'taskDescription': taskDescription,
      'assignedTo': assignedTo,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      status: json['status'] ?? false,
      taskDescription: json['taskDescription'],
      assignedTo: json['assignedTo'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      notes: json['notes'],
    );
  }
}
