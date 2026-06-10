import 'category_model.dart';

class TaskModel {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final String? description;
  final bool isCompleted;
  final int priority;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CategoryModel? category;

  TaskModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = 2,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.category,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      priority: json['priority'] as int? ?? 2,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      category: json['categories'] != null
          ? CategoryModel.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
    };
    if (id.isNotEmpty) data['id'] = id;
    if (categoryId != null) data['category_id'] = categoryId;
    return data;
  }

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? title,
    String? description,
    bool? isCompleted,
    int? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    CategoryModel? category,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }
}
