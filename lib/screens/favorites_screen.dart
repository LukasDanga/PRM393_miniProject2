import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/favorite_service.dart';
import 'task_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();
    final favorites = context.watch<FavoriteService>();
    final favoriteTasks = db.tasks
        .where((task) => favorites.isFavorite(task.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Yêu thích',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildCountBadge(favorites.count),
          ),
        ],
      ),
      body: favorites.isReady
          ? _buildBody(context, favoriteTasks, favorites)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<TaskModel> favoriteTasks,
    FavoriteService favorites,
  ) {
    if (favorites.favorites.isEmpty) {
      return _buildEmptyState();
    }

    if (favoriteTasks.isEmpty) {
      return _buildSnapshotList(context, favorites);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildDatabaseBanner(favorites.count),
        const SizedBox(height: 12),
        ...favoriteTasks.map(
          (task) => _buildTaskTile(context, task, favorites),
        ),
      ],
    );
  }

  Widget _buildDatabaseBanner(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storage_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SQLite local database',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count task được lưu trong bảng favorites',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    TaskModel task,
    FavoriteService favorites,
  ) {
    final dueText = task.dueDate != null
        ? DateFormat('dd/MM/yyyy').format(task.dueDate!)
        : 'Không deadline';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.favorite_rounded, color: Color(0xFFF43F5E)),
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              _buildMiniTag(task.priorityLabel, _priorityColor(task.priority)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dueText,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Bỏ yêu thích',
          icon: const Icon(Icons.favorite_rounded, color: Color(0xFFF43F5E)),
          onPressed: () => favorites.removeFavorite(task.id),
        ),
      ),
    );
  }

  Widget _buildSnapshotList(BuildContext context, FavoriteService favorites) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildDatabaseBanner(favorites.count),
        const SizedBox(height: 12),
        ...favorites.favorites.map((item) {
          final dueText = item.dueDate != null
              ? DateFormat('dd/MM/yyyy').format(item.dueDate!)
              : 'Không deadline';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Color(0xFFF43F5E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dueText,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Bỏ yêu thích',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => favorites.removeFavorite(item.taskId),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: Color(0xFFF43F5E),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có task yêu thích',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn biểu tượng trái tim trên task để lưu vào SQLite.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 15,
            color: Color(0xFFF43F5E),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF43F5E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _priorityColor(int priority) {
    return switch (priority) {
      1 => const Color(0xFF059669),
      2 => const Color(0xFFD97706),
      3 => const Color(0xFFDC2626),
      _ => const Color(0xFF64748B),
    };
  }
}
