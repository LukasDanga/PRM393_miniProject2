import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/task_model.dart';
import 'add_edit_task_screen.dart';
import 'category_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFilter = 0;
  String? _selectedCategoryId;
  int? _selectedPriority;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final auth = context.read<AuthService>();
    final db = context.read<DatabaseService>();
    if (auth.currentUser != null) {
      db.fetchTasks(auth.currentUser!.id);
      db.fetchCategories(auth.currentUser!.id);
    }
  }

  List<TaskModel> _filteredTasks(List<TaskModel> tasks) {
    var filtered = tasks;

    if (_selectedFilter == 0) {
      final today = DateTime.now();
      filtered = filtered.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.year == today.year &&
            t.dueDate!.month == today.month &&
            t.dueDate!.day == today.day;
      }).toList();
    } else if (_selectedFilter == 1) {
      filtered = filtered.where((t) => !t.isCompleted).toList();
    } else if (_selectedFilter == 2) {
      filtered = filtered.where((t) => t.isCompleted).toList();
    }

    if (_selectedCategoryId != null) {
      filtered =
          filtered.where((t) => t.categoryId == _selectedCategoryId).toList();
    }

    if (_selectedPriority != null) {
      filtered =
          filtered.where((t) => t.priority == _selectedPriority).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final db = context.watch<DatabaseService>();

    final filteredTasks = _filteredTasks(db.tasks);

    return Scaffold(
      appBar: AppBar(
        title: Text('Xin chào, ${auth.currentUser?.fullName ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(db),
          Expanded(
            child:
                db.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        return _buildTaskCard(filteredTasks[index], db);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar(DatabaseService db) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Hôm nay', 0),
                const SizedBox(width: 8),
                _buildFilterChip('Chưa xong', 1),
                const SizedBox(width: 8),
                _buildFilterChip('Đã xong', 2),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryDropdown(db),
                const SizedBox(width: 8),
                _buildPriorityDropdown(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = index;
        });
      },
    );
  }

  Widget _buildCategoryDropdown(DatabaseService db) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: _selectedCategoryId,
        hint: const Text('Danh mục'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Tất cả')),
          ...db.categories.map(
            (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedCategoryId = value;
          });
        },
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int?>(
        value: _selectedPriority,
        hint: const Text('Ưu tiên'),
        items: const [
          DropdownMenuItem(value: null, child: Text('Tất cả')),
          DropdownMenuItem(value: 1, child: Text('Thấp')),
          DropdownMenuItem(value: 2, child: Text('Trung bình')),
          DropdownMenuItem(value: 3, child: Text('Cao')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedPriority = value;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có công việc nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn + để thêm công việc mới',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, DatabaseService db) {
    final category = task.category;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            db.toggleTask(task.id, value ?? false);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 8),
                _priorityBadge(task.priority),
                const SizedBox(width: 8),
                if (task.dueDate != null)
                  Text(
                    DateFormat('dd/MM').format(task.dueDate!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTaskScreen(task: task),
                ),
              );
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Xóa task'),
                      content: const Text('Bạn có chắc muốn xóa?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                await db.deleteTask(task.id);
              }
            }
          },
          itemBuilder:
              (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa')),
              ],
        ),
      ),
    );
  }

  Widget _priorityBadge(int priority) {
    Color color;
    switch (priority) {
      case 1:
        color = Colors.green;
      case 2:
        color = Colors.orange;
      case 3:
        color = Colors.red;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority == 1 ? 'Thấp' : priority == 2 ? 'TB' : 'Cao',
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
