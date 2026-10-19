enum TaskPriority { low, medium, high }

enum TaskStatus { pending, completed }

class TaskModel {
  final int? id;
  final String? syncId;
  final bool isDeleted;
  final DateTime? updatedAt;
  final String title;
  final String? description;
  final String category;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final DateTime createdAt;

  TaskModel({
    this.id,
    this.syncId,
    this.isDeleted = false,
    this.updatedAt,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.dueDate,
    this.reminderTime,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sync_id': syncId,
      'is_deleted': isDeleted ? 1 : 0,
      'updated_at': updatedAt?.toIso8601String(),
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.index,
      'status': status.index,
      'due_date': dueDate?.toIso8601String(),
      'reminder_time': reminderTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      syncId: map['sync_id'],
      isDeleted: map['is_deleted'] == 1,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      title: map['title'],
      description: map['description'],
      category: map['category'],
      priority: TaskPriority.values[map['priority']],
      status: TaskStatus.values[map['status']],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  TaskModel copyWith({
    int? id,
    String? syncId,
    bool? isDeleted,
    DateTime? updatedAt,
    String? title,
    String? description,
    String? category,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? reminderTime,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      syncId: syncId ?? this.syncId,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
