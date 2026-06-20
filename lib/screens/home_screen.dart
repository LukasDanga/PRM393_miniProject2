import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/favorite_service.dart';
import '../models/task_model.dart';
import 'add_edit_task_screen.dart';
import 'task_detail_screen.dart';
import 'category_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showTodayOnly = false;

  // Draft filter values (before apply)
  Set<String> _draftStatus = {};
  Set<String> _draftCategories = {};
  Set<int> _draftPriorities = {};

  // Applied filter values (after apply)
  Set<String> _statusFilter = {};
  Set<String> _categoryFilter = {};
  Set<int> _priorityFilter = {};

  bool get _hasActiveFilter =>
      _statusFilter.isNotEmpty ||
      _categoryFilter.isNotEmpty ||
      _priorityFilter.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final auth = context.read<AuthService>();
    final db = context.read<DatabaseService>();
    final favorites = context.read<FavoriteService>();
    if (auth.currentUser != null) {
      db.reset();
      favorites.loadFavorites();
      db.fetchTasks(auth.currentUser!.id);
      db.fetchCategories(auth.currentUser!.id);
    }
  }

  List<TaskModel> _filteredTasks(List<TaskModel> tasks) {
    var filtered = tasks;

    if (_showTodayOnly) {
      final today = DateTime.now();
      filtered = filtered.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.year == today.year &&
            t.dueDate!.month == today.month &&
            t.dueDate!.day == today.day;
      }).toList();
    }

    if (_statusFilter.contains('pending')) {
      filtered = filtered.where((t) => !t.isCompleted).toList();
    }
    if (_statusFilter.contains('done')) {
      filtered = filtered.where((t) => t.isCompleted).toList();
    }

    if (_categoryFilter.isNotEmpty) {
      filtered = filtered
          .where((t) => _categoryFilter.contains(t.categoryId))
          .toList();
    }

    if (_priorityFilter.isNotEmpty) {
      filtered = filtered
          .where((t) => _priorityFilter.contains(t.priority))
          .toList();
    }

    return filtered;
  }

  void _showFilterSheet(DatabaseService db) {
    _draftStatus = Set.from(_statusFilter);
    _draftCategories = Set.from(_categoryFilter);
    _draftPriorities = Set.from(_priorityFilter);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bộ lọc',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Trạng thái',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _filterChip(
                        ctx,
                        setSheetState,
                        'Chưa xong',
                        _draftStatus,
                        'pending',
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        ctx,
                        setSheetState,
                        'Đã xong',
                        _draftStatus,
                        'done',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Danh mục',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: db.categories.map((c) {
                      final color = Color(
                        int.parse(c.color.replaceFirst('#', '0xFF')),
                      );
                      return _filterChip(
                        ctx,
                        setSheetState,
                        c.name,
                        _draftCategories,
                        c.id,
                        color: color,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Mức ưu tiên',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _filterChip(
                        ctx,
                        setSheetState,
                        'Thấp',
                        _draftPriorities,
                        1,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        ctx,
                        setSheetState,
                        'TB',
                        _draftPriorities,
                        2,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        ctx,
                        setSheetState,
                        'Cao',
                        _draftPriorities,
                        3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = {};
                              _categoryFilter = {};
                              _priorityFilter = {};
                              _showTodayOnly = false;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Bỏ lọc'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = Set.from(_draftStatus);
                              _categoryFilter = Set.from(_draftCategories);
                              _priorityFilter = Set.from(_draftPriorities);
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Áp dụng bộ lọc'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip<T>(
    BuildContext ctx,
    void Function(void Function()) setSheetState,
    String label,
    Set<T> selectedSet,
    T value, {
    Color? color,
  }) {
    final isSelected = selectedSet.contains(value);
    return GestureDetector(
      onTap: () {
        setSheetState(() {
          if (isSelected) {
            selectedSet.remove(value);
          } else {
            selectedSet.add(value);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? const Color(0xFF059669)).withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (color ?? const Color(0xFF059669))
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? (color ?? const Color(0xFF059669))
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final db = context.watch<DatabaseService>();
    final favorites = context.watch<FavoriteService>();
    final filteredTasks = _filteredTasks(db.tasks);
    final todayTasks = db.tasks.where((t) {
      if (t.dueDate == null) return false;
      final now = DateTime.now();
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth, todayTasks.length, favorites.count),
            _buildFilterBar(db),
            Expanded(
              child: db.isLoading
                  ? _buildLoading()
                  : filteredTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) =>
                          _buildTaskCard(filteredTasks[index], db, favorites),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            PageRouteBuilder(
              pageBuilder: (_, _, _) => const AddEditTaskScreen(),
              transitionsBuilder: (_, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
          if (result == true) _showSnack('Đã thêm task');
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeader(AuthService auth, int todayCount, int favoriteCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào,',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            auth.currentUser?.fullName ?? 'User',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.today_rounded,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$todayCount hôm nay',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Yêu thích',
                icon: Badge(
                  isLabelVisible: favoriteCount > 0,
                  label: Text('$favoriteCount'),
                  child: const Icon(Icons.favorite_border_rounded, size: 22),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
              IconButton(
                tooltip: 'Danh mục',
                icon: const Icon(Icons.grid_view_rounded, size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen()),
                ),
              ),
              IconButton(
                tooltip: 'Hồ sơ',
                icon: const Icon(Icons.person_outlined, size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(DatabaseService db) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _buildChip(
            'Tất cả',
            false,
            () => setState(() => _showTodayOnly = false),
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Hôm nay',
            _showTodayOnly,
            () => setState(() => _showTodayOnly = true),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showFilterSheet(db),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _hasActiveFilter
                    ? const Color(0xFF059669).withValues(alpha: 0.1)
                    : Colors.white,
                border: Border.all(
                  color: _hasActiveFilter
                      ? const Color(0xFF059669)
                      : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: _hasActiveFilter
                        ? const Color(0xFF059669)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Lọc',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _hasActiveFilter
                          ? const Color(0xFF059669)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  if (_hasActiveFilter) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_statusFilter.length + _categoryFilter.length + _priorityFilter.length}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF059669) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 16,
              width: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  height: 24,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  width: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 36,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Không có công việc nào',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn + để thêm công việc mới',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    TaskModel task,
    DatabaseService db,
    FavoriteService favorites,
  ) {
    final category = task.category;
    final color = category != null
        ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
        : null;
    final isFavorite = favorites.isFavorite(task.id);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFDC2626),
        ),
      ),
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
          await favorites.removeFavorite(task.id);
          _showSnack('Đã xóa task');
        }
        return false;
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  db.toggleTask(task.id, !task.isCompleted);
                  _showSnack(
                    task.isCompleted
                        ? 'Đã đánh dấu chưa xong'
                        : 'Đã hoàn thành',
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? const Color(0xFF059669)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: task.isCompleted
                          ? const Color(0xFF059669)
                          : const Color(0xFFCBD5E1),
                      width: task.isCompleted ? 0 : 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A),
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (color != null && category != null)
                          _buildTag(category.name, color),
                        _buildPriorityTag(task.priority),
                        if (task.dueDate != null)
                          _buildTag(
                            DateFormat('dd/MM').format(task.dueDate!),
                            const Color(0xFF64748B),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Bỏ yêu thích' : 'Thêm yêu thích',
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 21,
                  color: isFavorite
                      ? const Color(0xFFF43F5E)
                      : const Color(0xFF94A3B8),
                ),
                onPressed: () async {
                  final added = await favorites.toggleFavorite(task);
                  _showSnack(added ? 'Đã lưu vào SQLite' : 'Đã bỏ yêu thích');
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditTaskScreen(task: task),
                      ),
                    );
                    if (result == true) _showSnack('Đã cập nhật task');
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                      await favorites.removeFavorite(task.id);
                      _showSnack('Đã xóa task');
                    }
                  }
                },
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPriorityTag(int priority) {
    const labels = {1: 'Thấp', 2: 'TB', 3: 'Cao'};
    const colors = {
      1: Color(0xFF059669),
      2: Color(0xFFD97706),
      3: Color(0xFFDC2626),
    };
    return _buildTag(labels[priority]!, colors[priority]!);
  }
}
