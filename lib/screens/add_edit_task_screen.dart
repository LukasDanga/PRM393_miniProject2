import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/ollama_service.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../widgets/icon_mapping.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? task;
  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  String? _selectedCategoryId;
  int _priority = 2;
  DateTime? _dueDate;
  bool _isLoading = false;

  // AI state
  bool _isGenerating = false;
  AiSuggestion? _suggestion;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedCategoryId = task.categoryId;
      _priority = task.priority;
      _dueDate = task.dueDate;
    }

    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _descriptionController.removeListener(_onTextChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _generateWithAi() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _suggestion = null;
    });

    final suggestion = await OllamaService.suggest(title);

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _suggestion = suggestion;
      _descriptionController.text = suggestion.description;
    });
  }

  Future<void> _createSuggestedCategory() async {
    if (_suggestion?.categoryName == null) return;

    final auth = context.read<AuthService>();
    final db = context.read<DatabaseService>();
    if (auth.currentUser == null) return;

    // Check if a category with this name already exists
    final existing = db.categories.where(
      (c) => c.name.toLowerCase() == _suggestion!.categoryName!.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      setState(() => _selectedCategoryId = existing.first.id);
      _showSnackBar('Đã chọn danh mục "${existing.first.name}"');
      return;
    }

    // Create a new category
    final newCat = CategoryModel(
      id: '',
      userId: auth.currentUser!.id,
      name: _suggestion!.categoryName!,
      color: '#059669',
      icon: _suggestion!.categoryIcon ?? 'folder',
    );

    final error = await db.addCategory(newCat);
    if (!mounted) return;

    if (error != null) {
      _showSnackBar('Lỗi tạo danh mục: $error');
      return;
    }

    // Select the newly created category
    final created = db.categories.lastWhere(
      (c) => c.name == _suggestion!.categoryName,
      orElse: () => db.categories.last,
    );
    setState(() => _selectedCategoryId = created.id);
    _showSnackBar('Đã tạo danh mục "${created.name}"');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF059669)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final db = context.read<DatabaseService>();

    if (_isEditing) {
      final task = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        priority: _priority,
        dueDate: _dueDate,
      );
      await db.updateTask(task);
    } else {
      final task = TaskModel(
        id: '',
        userId: auth.currentUser!.id,
        categoryId: _selectedCategoryId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
      );
      await db.addTask(task);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa task' : 'Thêm task'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _isEditing ? 'Cập nhật' : 'Thêm',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText: 'Nhập tiêu đề công việc',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập tiêu đề';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field with AI generate button
              TextFormField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Thêm mô tả chi tiết (không bắt buộc)',
                ),
              ),
              const SizedBox(height: 8),

              // AI Generate / Re-generate Button
              if (_titleController.text.trim().isNotEmpty)
                _descriptionController.text.trim().isEmpty
                    ? _buildGenerateButton()
                    : _buildRegenerateButton(),

              // AI Category Suggestion Card
              if (_suggestion?.categoryName != null)
                _buildCategorySuggestion(db),

              const SizedBox(height: 16),
              Text(
                'Danh mục',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(null, 'Tất cả', null),
                    ...db.categories.map((cat) {
                      final color = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
                      return _buildCategoryChip(cat.id, cat.name, color);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Mức ưu tiên',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityChip(1, 'Thấp', const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  _buildPriorityChip(2, 'Trung bình', const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _buildPriorityChip(3, 'Cao', const Color(0xFFDC2626)),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Ngày hết hạn',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null
                            ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                            : 'Chọn ngày',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: _dueDate != null
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AI Generate Button ──────────────────────────────────

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _isGenerating ? null : _generateWithAi,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isGenerating)
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.auto_awesome_outlined, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                _isGenerating ? 'Đang tạo...' : 'Tạo mô tả bằng AI',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegenerateButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _isGenerating ? null : _generateWithAi,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isGenerating)
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  ),
                )
              else
                const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 6),
              Text(
                _isGenerating ? 'Đang tạo lại...' : 'Tạo lại mô tả bằng AI',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AI Category Suggestion ──────────────────────────────

  Widget _buildCategorySuggestion(DatabaseService db) {
    final name = _suggestion!.categoryName!;
    final iconName = _suggestion!.categoryIcon ?? 'folder';
    final iconData = getIconData(iconName);

    // Check if this category already exists
    final exists = db.categories.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDD6FE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, size: 14, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 6),
                Text(
                  'AI gợi ý danh mục',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _suggestion = AiSuggestion(
                    description: _suggestion!.description,
                  )),
                  child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: exists ? () {
                final cat = db.categories.firstWhere(
                  (c) => c.name.toLowerCase() == name.toLowerCase(),
                );
                setState(() => _selectedCategoryId = cat.id);
                _showSnackBar('Đã chọn danh mục "${cat.name}"');
              } : _createSuggestedCategory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconData, size: 18, color: const Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: exists
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        exists ? 'Chọn' : '+ Tạo mới',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: exists
                              ? const Color(0xFF059669)
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String? id, String name, Color? color) {
    final selected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryId = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF059669) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null)
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              if (color != null) const SizedBox(width: 6),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(int priority, String label, Color color) {
    final selected = _priority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = priority),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Icon(
                priority == 1 ? Icons.arrow_downward_rounded
                    : priority == 2 ? Icons.remove_rounded
                    : Icons.arrow_upward_rounded,
                size: 20,
                color: selected ? color : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
