import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/favorite_service.dart';
import '../models/task_model.dart';
import '../widgets/icon_mapping.dart';
import 'add_edit_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();
    final favorites = context.watch<FavoriteService>();
    // Get the latest version of this task from the database
    final current = db.tasks.where((t) => t.id == task.id).firstOrNull ?? task;
    final isFavorite = favorites.isFavorite(current.id);
    final category = current.category;
    final categoryColor = category != null
        ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Bỏ yêu thích' : 'Thêm yêu thích',
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 22,
              color: isFavorite ? const Color(0xFFF43F5E) : null,
            ),
            onPressed: () async {
              final added = await favorites.toggleFavorite(current);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      added ? 'Đã lưu vào SQLite' : 'Đã bỏ yêu thích',
                      style: GoogleFonts.outfit(),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTaskScreen(task: current),
                ),
              );
              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã cập nhật task',
                      style: GoogleFonts.outfit(),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: Color(0xFFDC2626),
            ),
            onPressed: () => _confirmDelete(context, db, favorites, current),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    db.toggleTask(current.id, !current.isCompleted);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: current.isCompleted
                          ? const Color(0xFF059669)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: current.isCompleted
                            ? const Color(0xFF059669)
                            : const Color(0xFFCBD5E1),
                        width: current.isCompleted ? 0 : 1.5,
                      ),
                    ),
                    child: current.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    current.title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: current.isCompleted
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                      decoration: current.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tags row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(current.isCompleted),
                _buildPriorityChip(current.priority),
                if (category != null && categoryColor != null)
                  _buildCategoryChip(
                    category.name,
                    categoryColor,
                    getIconData(category.icon),
                  ),
              ],
            ),

            const SizedBox(height: 28),

            // Description section
            _buildSection(
              icon: Icons.notes_rounded,
              title: 'Mô tả',
              child:
                  current.description != null && current.description!.isNotEmpty
                  ? Text(
                      current.description!,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: const Color(0xFF334155),
                        height: 1.6,
                      ),
                    )
                  : Text(
                      'Không có mô tả',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Due date section
            _buildSection(
              icon: Icons.calendar_today_rounded,
              title: 'Ngày hết hạn',
              child: current.dueDate != null
                  ? Row(
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, dd/MM/yyyy',
                          ).format(current.dueDate!),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: _isOverdue(current)
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_isOverdue(current)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFDC2626,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Quá hạn',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      'Không có ngày hết hạn',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Timestamps
            _buildSection(
              icon: Icons.access_time_rounded,
              title: 'Thời gian',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (current.createdAt != null)
                    _buildTimestamp('Tạo lúc', current.createdAt!),
                  if (current.updatedAt != null) ...[
                    const SizedBox(height: 6),
                    _buildTimestamp('Cập nhật', current.updatedAt!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Toggle completion button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  db.toggleTask(current.id, !current.isCompleted);
                },
                icon: Icon(
                  current.isCompleted
                      ? Icons.replay_rounded
                      : Icons.check_rounded,
                  size: 20,
                ),
                label: Text(
                  current.isCompleted
                      ? 'Đánh dấu chưa xong'
                      : 'Đánh dấu hoàn thành',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: current.isCompleted
                        ? const Color(0xFFD97706)
                        : const Color(0xFF059669),
                  ),
                  foregroundColor: current.isCompleted
                      ? const Color(0xFFD97706)
                      : const Color(0xFF059669),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isOverdue(TaskModel task) {
    if (task.dueDate == null || task.isCompleted) return false;
    return task.dueDate!.isBefore(DateTime.now());
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(padding: const EdgeInsets.only(left: 26), child: child),
      ],
    );
  }

  Widget _buildTimestamp(String label, DateTime dateTime) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Text(
          DateFormat('dd/MM/yyyy HH:mm').format(dateTime),
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF059669).withValues(alpha: 0.1)
            : const Color(0xFFD97706).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isCompleted
                ? const Color(0xFF059669)
                : const Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
          Text(
            isCompleted ? 'Hoàn thành' : 'Đang làm',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCompleted
                  ? const Color(0xFF059669)
                  : const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(int priority) {
    const labels = {1: 'Thấp', 2: 'Trung bình', 3: 'Cao'};
    const colors = {
      1: Color(0xFF059669),
      2: Color(0xFFD97706),
      3: Color(0xFFDC2626),
    };
    const icons = {
      1: Icons.arrow_downward_rounded,
      2: Icons.remove_rounded,
      3: Icons.arrow_upward_rounded,
    };
    final color = colors[priority]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[priority], size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            labels[priority]!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String name, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DatabaseService db,
    FavoriteService favorites,
    TaskModel task,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    if (confirm == true && context.mounted) {
      await db.deleteTask(task.id);
      await favorites.removeFavorite(task.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
