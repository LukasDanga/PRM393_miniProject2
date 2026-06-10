import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/category_model.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.folder_outlined;
  bool _isEditing = false;
  String? _editingId;

  final List<IconData> _availableIcons = [
    Icons.folder_outlined,
    Icons.work_outlined,
    Icons.school_outlined,
    Icons.home_outlined,
    Icons.fitness_center_outlined,
    Icons.shopping_cart_outlined,
    Icons.music_note_outlined,
    Icons.book_outlined,
    Icons.code_outlined,
    Icons.language_outlined,
    Icons.emoji_events_outlined,
    Icons.flight_outlined,
    Icons.pets_outlined,
    Icons.favorite_outlined,
    Icons.star_outlined,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _selectedColor = Colors.blue;
    _selectedIcon = Icons.folder_outlined;
    _isEditing = false;
    _editingId = null;
  }

  void _editCategory(CategoryModel category) {
    setState(() {
      _nameController.text = category.name;
      _selectedColor =
          Color(int.parse(category.color.replaceFirst('#', '0xFF')));
      _selectedIcon = Icons.folder_outlined;
      _isEditing = true;
      _editingId = category.id;
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
        icon: _selectedIcon.codePoint.toString(),
      );
      final error = await db.updateCategory(category);
      if (error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    } else {
      final category = CategoryModel(
        id: '',
        userId: auth.currentUser!.id,
        name: _nameController.text.trim(),
        color: hexColor,
        icon: _selectedIcon.codePoint.toString(),
      );
      final error = await db.addCategory(category);
      if (error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }

    _resetForm();
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xóa danh mục'),
            content: const Text('Các task trong danh mục cũng sẽ bị xóa. Tiếp tục?'),
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
      final db = context.read<DatabaseService>();
      await db.deleteCategory(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý danh mục')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên danh mục',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isEditing
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _resetForm,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Màu sắc: '),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('Chọn màu'),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerColor: _selectedColor,
                                    onColorChanged: (color) {
                                      setState(() {
                                        _selectedColor = color;
                                      });
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _availableIcons.map((icon) {
                      final isSelected = _selectedIcon == icon;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(icon, size: 20),
                          label: const SizedBox.shrink(),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedIcon = icon;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveCategory,
                    icon: Icon(_isEditing ? Icons.save : Icons.add),
                    label: Text(_isEditing ? 'Cập nhật' : 'Thêm danh mục'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child:
                db.categories.isEmpty
                    ? const Center(child: Text('Chưa có danh mục nào'))
                    : ListView.builder(
                      itemCount: db.categories.length,
                      itemBuilder: (context, index) {
                        final cat = db.categories[index];
                        final color = Color(
                          int.parse(cat.color.replaceFirst('#', '0xFF')),
                        );
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color,
                            child: Icon(
                              IconData(
                                int.parse(cat.icon),
                                fontFamily: 'MaterialIcons',
                              ),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(cat.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editCategory(cat),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outlined,
                                  color: Colors.red,
                                ),
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
