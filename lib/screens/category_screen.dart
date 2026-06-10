import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/category_model.dart';
import '../widgets/icon_mapping.dart';

class _IconOption {
  final String name;
  final IconData icon;
  const _IconOption(this.name, this.icon);
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFF4A90D9);
  String _selectedIconName = 'folder';
  bool _isAdding = false;
  bool _isEditing = false;
  String? _editingId;

  final List<_IconOption> _availableIcons = [
    _IconOption('folder', Icons.folder_outlined),
    _IconOption('work', Icons.work_outlined),
    _IconOption('school', Icons.school_outlined),
    _IconOption('home', Icons.home_outlined),
    _IconOption('fitness', Icons.fitness_center_outlined),
    _IconOption('shopping', Icons.shopping_cart_outlined),
    _IconOption('music', Icons.music_note_outlined),
    _IconOption('book', Icons.book_outlined),
    _IconOption('code', Icons.code_outlined),
    _IconOption('language', Icons.language_outlined),
    _IconOption('trophy', Icons.emoji_events_outlined),
    _IconOption('flight', Icons.flight_outlined),
    _IconOption('pets', Icons.pets_outlined),
    _IconOption('heart', Icons.favorite_outlined),
    _IconOption('star', Icons.star_outlined),
    _IconOption('person', Icons.person_outlined),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _selectedColor = const Color(0xFF4A90D9);
    _selectedIconName = 'folder';
    _isAdding = false;
    _isEditing = false;
    _editingId = null;
  }

  void _editCategory(CategoryModel cat) {
    setState(() {
      _nameController.text = cat.name;
      _selectedColor = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
      _selectedIconName = cat.icon;
      _isAdding = true;
      _isEditing = true;
      _editingId = cat.id;
    });
  }

  Future<void> _saveCategory() async {
    if (_nameController.text.trim().isEmpty) return;
    final auth = context.read<AuthService>();
    final db = context.read<DatabaseService>();
    final hexColor =
        '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    if (_isEditing && _editingId != null) {
      final category = CategoryModel(
        id: _editingId!,
        userId: auth.currentUser!.id,
        name: _nameController.text.trim(),
        color: hexColor,
        icon: _selectedIconName,
      );
      await db.updateCategory(category);
      _showSnack('Đã cập nhật danh mục');
    } else {
      final category = CategoryModel(
        id: '',
        userId: auth.currentUser!.id,
        name: _nameController.text.trim(),
        color: hexColor,
        icon: _selectedIconName,
      );
      await db.addCategory(category);
      _showSnack('Đã thêm danh mục');
    }
    _resetForm();
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

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa danh mục'),
        content: const Text('Task trong danh mục sẽ bỏ trống danh mục. Tiếp tục?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<DatabaseService>().deleteCategory(id);
      _showSnack('Đã xóa danh mục');
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chọn màu'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (c) => setState(() => _selectedColor = c),
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Danh mục')),
      body: Column(
        children: [
          if (_isAdding)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Tên danh mục',
                            hintText: 'VD: Học tập',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showColorPicker,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _availableIcons.map((item) {
                        final sel = _selectedIconName == item.name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedIconName = item.name),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: sel ? _selectedColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel ? _selectedColor : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(item.icon, size: 20,
                                color: sel ? _selectedColor : const Color(0xFF94A3B8)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetForm,
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveCategory,
                          icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded, size: 18),
                          label: Text(_isEditing ? 'Cập nhật' : 'Thêm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: _isAdding
                  ? null
                  : OutlinedButton.icon(
                      onPressed: () => setState(() => _isAdding = true),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Thêm danh mục'),
                    ),
            ),
          ),
          Expanded(
            child: db.categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.folder_outlined, size: 32, color: Color(0xFF059669)),
                        ),
                        const SizedBox(height: 16),
                        Text('Chưa có danh mục nào', style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A),
                        )),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: db.categories.length,
                    itemBuilder: (context, index) {
                      final cat = db.categories[index];
                      final color = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(getIconData(cat.icon), size: 22, color: color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat.name, style: GoogleFonts.outfit(
                                    fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A),
                                  )),
                                  Text('${db.tasks.where((t) => t.categoryId == cat.id).length} task',
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                              onPressed: () => _editCategory(cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                              onPressed: () => _deleteCategory(cat.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
