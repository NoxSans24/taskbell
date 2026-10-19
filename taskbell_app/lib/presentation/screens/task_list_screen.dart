import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/models/task_model.dart';
import 'package:taskbell_app/logic/providers/category_provider.dart';
import 'package:taskbell_app/logic/providers/task_provider.dart';
import 'package:taskbell_app/logic/providers/sync_provider.dart';
import 'package:taskbell_app/presentation/screens/add_edit_task_screen.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';
import 'package:taskbell_app/presentation/widgets/comic_components.dart';
import 'package:taskbell_app/presentation/widgets/sync_status_button.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _searchQuery = '';
  String _filterCategory = 'Semua';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final tasksAsync = ref.watch(taskListProvider);
    final tasks = tasksAsync.value ?? const <TaskModel>[];

    final storedCategories = ref
            .watch(categoryListProvider)
            .value
            ?.map((category) => category.name)
            .toList() ??
        const <String>[];
    final categories = <String>[
      'Semua',
      ...(storedCategories.isNotEmpty
          ? storedCategories
          : {for (final task in tasks) task.category}),
    ];
    final activeFilter =
        categories.contains(_filterCategory) ? _filterCategory : 'Semua';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Tugas",
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: const [SyncStatusButton()],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(palette, categories, activeFilter),
          Expanded(
            child: tasksAsync.when(
              data: (loadedTasks) {
                final filteredTasks = loadedTasks.where((t) {
                  final matchesSearch = t.title
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  final matchesCategory =
                      activeFilter == 'Semua' || t.category == activeFilter;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Tidak ada tugas ditemukan",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) =>
                      _buildTaskItem(palette, filteredTasks[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Gagal memuat tugas dari perangkat.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            ref.read(taskListProvider.notifier).fetchTasks(),
                        child: const Text("Coba lagi"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(
    AppPalette palette,
    List<String> categories,
    String activeFilter,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ComicCard(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Cari tugas...",
                icon: AppIcon(AppIcons.search),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = activeFilter == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ComicCard(
                    onTap: () => setState(() => _filterCategory = category),
                    color: isSelected ? palette.secondary : palette.surface,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? palette.onAccent : palette.ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(TaskModel task) async {
    if (task.id == null) return;

    final palette = AppPalette.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            Text('Apakah kamu yakin ingin menghapus tugas "${task.title}"?'),
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

    try {
      await ref.read(taskListProvider.notifier).deleteTask(task.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil dihapus.')),
      );
      await ref.read(syncControllerProvider.notifier).syncNow();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus tugas.')),
      );
    }
  }

  Future<void> _toggleTask(TaskModel task) async {
    await ref.read(taskListProvider.notifier).toggleTaskStatus(task);
    if (!mounted) return;
    await ref.read(syncControllerProvider.notifier).syncNow();
  }

  Widget _buildTaskItem(AppPalette palette, TaskModel task) {
    final isOverdue = task.status == TaskStatus.pending &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());
    final isCompleted = task.status == TaskStatus.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ComicCard(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (c) => AddEditTaskScreen(task: task))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Semantics(
                button: true,
                checked: isCompleted,
                label: isCompleted
                    ? 'Tandai "${task.title}" belum selesai'
                    : 'Tandai "${task.title}" selesai',
                child: InkWell(
                  onTap: () => _toggleTask(task),
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              isCompleted ? palette.primary : palette.surface,
                          border: Border.all(color: palette.border, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isCompleted
                            ? AppIcon(
                                AppIcons.check,
                                size: 16,
                                color: palette.onPrimary,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.dueDate != null)
                      Text(
                        DateFormat('dd MMM, HH:mm').format(task.dueDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? palette.error : palette.muted,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                  ],
                ),
              ),
              if (task.priority == TaskPriority.high)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AppIcon(
                    AppIcons.flag,
                    size: 20,
                    color: palette.error,
                  ),
                ),
              PopupMenuButton<String>(
                icon: AppIcon(
                  AppIcons.moreVertical,
                  size: 20,
                  color: palette.ink,
                ),
                tooltip: 'Opsi Tugas',
                onSelected: (val) {
                  if (val == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => AddEditTaskScreen(task: task)),
                    );
                  } else if (val == 'delete') {
                    _deleteTask(task);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        AppIcon(AppIcons.pencil, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        AppIcon(
                          AppIcons.trash,
                          size: 18,
                          color: palette.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hapus',
                          style: TextStyle(color: palette.error),
                        ),
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
}
