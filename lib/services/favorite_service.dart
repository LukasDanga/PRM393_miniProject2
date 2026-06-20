import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';

class FavoriteItem {
  final String taskId;
  final String title;
  final String? description;
  final int priority;
  final DateTime? dueDate;
  final DateTime createdAt;

  FavoriteItem({
    required this.taskId,
    required this.title,
    this.description,
    required this.priority,
    this.dueDate,
    required this.createdAt,
  });

  factory FavoriteItem.fromMap(Map<String, Object?> map) {
    return FavoriteItem(
      taskId: map['task_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: map['priority'] as int? ?? 2,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'task_id': taskId,
      'title': title,
      'description': description,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FavoriteItem.fromTask(TaskModel task) {
    return FavoriteItem(
      taskId: task.id,
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: task.dueDate,
      createdAt: DateTime.now(),
    );
  }
}

class FavoriteService extends ChangeNotifier {
  static const _databaseName = 'taskflow_favorites.db';
  static const _tableName = 'favorites';

  Database? _database;
  final Map<String, FavoriteItem> _favorites = {};
  bool _isReady = false;

  List<FavoriteItem> get favorites =>
      _favorites.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get count => _favorites.length;
  bool get isReady => _isReady;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            task_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            priority INTEGER NOT NULL,
            due_date TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<void> loadFavorites() async {
    final db = await _db;
    final rows = await db.query(_tableName, orderBy: 'created_at DESC');

    _favorites
      ..clear()
      ..addEntries(
        rows.map((row) {
          final item = FavoriteItem.fromMap(row);
          return MapEntry(item.taskId, item);
        }),
      );

    _isReady = true;
    notifyListeners();
  }

  bool isFavorite(String taskId) => _favorites.containsKey(taskId);

  Future<void> addFavorite(TaskModel task) async {
    final db = await _db;
    final item = FavoriteItem.fromTask(task);

    await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _favorites[item.taskId] = item;
    notifyListeners();
  }

  Future<void> removeFavorite(String taskId) async {
    final db = await _db;

    await db.delete(_tableName, where: 'task_id = ?', whereArgs: [taskId]);

    _favorites.remove(taskId);
    notifyListeners();
  }

  Future<bool> toggleFavorite(TaskModel task) async {
    if (isFavorite(task.id)) {
      await removeFavorite(task.id);
      return false;
    }

    await addFavorite(task);
    return true;
  }

  Future<void> removeMissingTasks(Set<String> existingTaskIds) async {
    final staleIds = _favorites.keys
        .where((taskId) => !existingTaskIds.contains(taskId))
        .toList();
    if (staleIds.isEmpty) return;

    final db = await _db;
    final batch = db.batch();
    for (final taskId in staleIds) {
      batch.delete(_tableName, where: 'task_id = ?', whereArgs: [taskId]);
      _favorites.remove(taskId);
    }
    await batch.commit(noResult: true);
    notifyListeners();
  }
}
