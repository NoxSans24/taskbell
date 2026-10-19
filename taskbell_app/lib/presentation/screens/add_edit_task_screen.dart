import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/models/task_model.dart';
import 'package:taskbell_app/logic/providers/category_provider.dart';
import 'package:taskbell_app/logic/providers/sync_provider.dart';
import 'package:taskbell_app/logic/providers/task_provider.dart';
import 'package:taskbell_app/presentation/screens/category_screen.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';
import 'package:taskbell_app/presentation/widgets/comic_components.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? task;
  final DateTime? initialDate;

  const AddEditTaskScreen({super.key, this.task, this.initialDate});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedCategory;
  late TaskPriority _selectedPriority;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController =
        TextEditingController(text: widget.task?.description ?? '');
    _selectedCategory = widget.task?.category ?? 'Kuliah';
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
    _selectedDate = widget.task?.dueDate ?? widget.initialDate;

    if (widget.task?.dueDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.dueDate!);
    } else if (widget.initialDate != null) {
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    if (widget.task == null ||
        widget.task!.id == null ||
        _isSaving ||
        _isDeleting) {
      return;
    }

    final palette = AppPalette.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Apakah kamu yakin ingin menghapus tugas "${widget.task!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: palette.error),
            child: const Text('Hapus',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await ref.read(taskListProvider.notifier).deleteTask(widget.task!.id!);
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil dihapus.')),
      );
      Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('Gagal menghapus tugas: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;
      setState(() => _isDeleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus tugas: $e')),
      );
    }
  }

  Future<void> _saveTask() async {
    if (_isSaving || _isDeleting) return;
    if (!_formKey.currentState!.validate()) return;

    final categoryNames = ref
            .read(categoryListProvider)
            .value
            ?.map((category) => category.name)
            .toList() ??
        const <String>[];
    final effectiveCategory = categoryNames.contains(_selectedCategory)
        ? _selectedCategory
        : (categoryNames.isNotEmpty ? categoryNames.first : _selectedCategory);

    DateTime? finalDueDate;

    if (_selectedDate != null) {
      finalDueDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime?.hour ?? 23,
        _selectedTime?.minute ?? 59,
      );

      if (finalDueDate.isBefore(DateTime.now())) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tenggat waktu harus berada di masa mendatang.'),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final task = TaskModel(
      id: widget.task?.id,
      syncId: widget.task?.syncId,
      isDeleted: widget.task?.isDeleted ?? false,
      updatedAt: DateTime.now(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: effectiveCategory,
      priority: _selectedPriority,
      status: widget.task?.status ?? TaskStatus.pending,
      dueDate: finalDueDate,
      reminderTime: widget.task?.reminderTime,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.task == null) {
        await ref.read(taskListProvider.notifier).addTask(task);
      } else {
        await ref.read(taskListProvider.notifier).updateTask(task);
      }

      unawaited(ref.read(syncControllerProvider.notifier).syncNow());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.task == null
              ? 'Tugas berhasil disimpan!'
              : 'Tugas berhasil diperbarui!'),
        ),
      );

      Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('Gagal menyimpan tugas dari form: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan tugas: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final categoryNames = ref
            .watch(categoryListProvider)
            .value
            ?.map((category) => category.name)
            .toList() ??
        const <String>[];
    final availableCategories =
        categoryNames.isEmpty ? const ['Umum'] : categoryNames;
    final selectedCategory = availableCategories.contains(_selectedCategory)
        ? _selectedCategory
        : availableCategories.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? "Tambah Tugas" : "Edit Tugas",
            style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.task != null && widget.task!.id != null)
            IconButton(
              icon: AppIcon(AppIcons.trash, color: palette.error),
              tooltip: "Hapus Tugas",
              onPressed: (_isSaving || _isDeleting) ? null : _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Judul Tugas"),
              _buildTextField(_titleController, "Apa yang mau dikerjakan?",
                  required: true),
              const SizedBox(height: 16),
              _buildLabel("Deskripsi (Opsional)"),
              _buildTextField(_descController, "Detail tugas...", maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCategoryPicker(
                      availableCategories,
                      selectedCategory,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPriorityPicker(palette)),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabel("Tenggat Waktu"),
              _buildDateTimePicker(),
              const SizedBox(height: 32),
              ComicButton(
                text: _isSaving
                    ? "Menyimpan..."
                    : (_isDeleting
                        ? "Menghapus..."
                        : (widget.task == null
                            ? "Simpan Tugas"
                            : "Update Tugas")),
                onPressed: (_isSaving || _isDeleting) ? () {} : _saveTask,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool required = false, int maxLines = 1}) {
    return ComicCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
        validator: required ? (v) => v!.isEmpty ? "Wajib diisi" : null : null,
      ),
    );
  }

  Widget _buildCategoryPicker(List<String> names, String selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel("Kategori"),
            const Spacer(),
            IconButton(
              tooltip: 'Kelola kategori',
              visualDensity: VisualDensity.compact,
              icon: const AppIcon(AppIcons.settings, size: 18),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryScreen(),
                  ),
                );
                await ref.read(categoryListProvider.notifier).refresh();
              },
            ),
          ],
        ),
        ComicCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              items: names
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityPicker(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Prioritas"),
        ComicCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TaskPriority>(
              value: _selectedPriority,
              isExpanded: true,
              items: TaskPriority.values
                  .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                p == TaskPriority.high ? palette.error : null,
                            fontWeight: FontWeight.bold,
                          ))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPriority = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    final dateStr = _selectedDate == null
        ? "Pilih Tanggal"
        : DateFormat('dd MMM yyyy').format(_selectedDate!);
    final timeStr =
        _selectedTime == null ? "Pilih Jam" : _selectedTime!.format(context);

    return Row(
      children: [
        Expanded(
          child: ComicCard(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const AppIcon(AppIcons.calendar, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(dateStr, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ComicCard(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime ?? TimeOfDay.now(),
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const AppIcon(AppIcons.clock, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(timeStr, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
