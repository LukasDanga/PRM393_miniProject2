import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/task_model.dart';

class DatabaseService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<CategoryModel> _categories = [];
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  void reset() {
    _categories = [];
    _tasks = [];
    notifyListeners();
  }

  // ─── CATEGORIES ─────────────────────────────────────────

  Future<String?> fetchCategories(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      _categories = (response as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> addCategory(CategoryModel category) async {
    try {
      final response = await _supabase
          .from('categories')
          .insert(category.toJson())
          .select()
          .single();

      _categories.add(
        CategoryModel.fromJson(response),
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateCategory(CategoryModel category) async {
    try {
      await _supabase
          .from('categories')
          .update(category.toJson())
          .eq('id', category.id);

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteCategory(String id) async {
    try {
      await _supabase.from('categories').delete().eq('id', id);
      _categories.removeWhere((c) => c.id == id);
      for (var i = 0; i < _tasks.length; i++) {
        if (_tasks[i].categoryId == id) {
          _tasks[i] = _tasks[i].copyWith(categoryId: null, category: null);
        }
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── TASKS ──────────────────────────────────────────────

  Future<String?> fetchTasks(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('tasks')
          .select('*, categories(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _tasks = (response as List)
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> addTask(TaskModel task) async {
    try {
      final response = await _supabase
          .from('tasks')
          .insert(task.toJson())
          .select('*, categories(*)')
          .single();

      _tasks.insert(
        0,
        TaskModel.fromJson(response),
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateTask(TaskModel task) async {
    try {
      final response = await _supabase
          .from('tasks')
          .update(task.toJson())
          .eq('id', task.id)
          .select('*, categories(*)')
          .single();

      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = TaskModel.fromJson(response);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> toggleTask(String id, bool isCompleted) async {
    try {
      await _supabase
          .from('tasks')
          .update({'is_completed': isCompleted})
          .eq('id', id);

      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(isCompleted: isCompleted);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteTask(String id) async {
    try {
      await _supabase.from('tasks').delete().eq('id', id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
