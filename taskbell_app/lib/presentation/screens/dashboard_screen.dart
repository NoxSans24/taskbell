import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/models/task_model.dart';
import 'package:taskbell_app/logic/providers/auth_provider.dart';
import 'package:taskbell_app/logic/providers/task_provider.dart';
import 'package:taskbell_app/logic/providers/theme_provider.dart';
import 'package:taskbell_app/presentation/screens/add_edit_task_screen.dart';
import 'package:taskbell_app/presentation/screens/task_list_screen.dart';
import 'package:taskbell_app/presentation/screens/telegram_settings_screen.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';
import 'package:taskbell_app/presentation/widgets/comic_components.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final stats = ref.watch(taskStatsProvider);
    final tasksAsync = ref.watch(taskListProvider);
    final email = ref.watch(authControllerProvider).email;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref, palette, stats, email),
              const SizedBox(height: 20),
              _buildStatsGrid(context, palette, stats),
              const SizedBox(height: 24),
              _buildTelegramBanner(context, palette),
              const SizedBox(height: 24),
              _buildPrioritySection(context, palette, tasksAsync),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah tugas',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
          );
        },
        backgroundColor: palette.primary,
        child: AppIcon(AppIcons.plus, color: palette.onPrimary, size: 28),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AppPalette palette,
    Map<String, int> stats,
    String? email,
  ) {
    return ComicCard(
      color: palette.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.secondarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  "${stats['completed']} SELESAI",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: palette.ink,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                key: const ValueKey('account-button'),
                tooltip: 'Akun',
                onPressed: () => _openAccountSheet(context, ref),
                icon: const AppIcon(AppIcons.user),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Halo, ${_displayName(email)}!",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'Plus Jakarta Sans',
              fontVariations: [FontVariation('wght', 900)],
            ),
          ),
          const Text("Ayo selesaikan tugasmu hari ini!"),
          const SizedBox(height: 16),
          ComicButton(
            text: "+ Tambah Tugas Baru",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditTaskScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AppPalette palette,
    Map<String, int> stats,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatItem(
          context,
          palette,
          "Total Tugas",
          stats['total']!,
          palette.primarySoft,
        ),
        _buildStatItem(
          context,
          palette,
          "Tertunda",
          stats['pending']!,
          palette.secondary,
        ),
        _buildStatItem(
          context,
          palette,
          "Selesai",
          stats['completed']!,
          palette.successSoft,
        ),
        _buildStatItem(
          context,
          palette,
          "Overdue",
          stats['overdue']!,
          palette.errorSoft,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    AppPalette palette,
    String label,
    int value,
    Color color,
  ) {
    return ComicCard(
      color: palette.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: AppIcon(
                  AppIcons.tasks,
                  size: 18,
                  color: palette.ink,
                ),
              ),
              Text(
                label.substring(0, 3).toUpperCase(),
                style: TextStyle(fontSize: 10, color: palette.muted),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$value",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramBanner(BuildContext context, AppPalette palette) {
    return ComicCard(
      color: palette.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2AABEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: const AppIcon(AppIcons.send, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pengingat Telegram",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Hubungkan bot untuk notifikasi",
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
          ComicButton(
            text: "Atur",
            isFullWidth: false,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelegramSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection(
    BuildContext context,
    AppPalette palette,
    AsyncValue<List<TaskModel>> tasksAsync,
  ) {
    final tasks = tasksAsync.value ?? const <TaskModel>[];
    final upcoming = tasks.where((t) => t.status == TaskStatus.pending).toList()
      ..sort((a, b) {
        final aDate = a.dueDate;
        final bDate = b.dueDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
    final top = upcoming.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "PRIORITAS HARI INI",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskListScreen(),
                  ),
                );
              },
              child: Text(
                "Lihat Semua",
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (top.isEmpty)
          ComicCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Belum ada tugas aktif. Tambahkan tugas pertamamu.",
              style: TextStyle(color: palette.muted),
            ),
          )
        else
          ...top.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTaskCard(context, palette, task),
              )),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    AppPalette palette,
    TaskModel task,
  ) {
    final dueDate = task.dueDate;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

    final priorityLabel = switch (task.priority) {
      TaskPriority.high => "Tinggi",
      TaskPriority.medium => "Sedang",
      TaskPriority.low => "Rendah",
    };

    final priorityColor = switch (task.priority) {
      TaskPriority.high => palette.errorSoft,
      TaskPriority.medium => palette.secondarySoft,
      TaskPriority.low => palette.surfaceAlt,
    };

    return ComicCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddEditTaskScreen(task: task)),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  priorityLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.category,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ),
              const SizedBox(width: 8),
              if (dueDate != null)
                Text(
                  DateFormat('dd MMM').format(dueDate),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    color: isOverdue ? palette.error : palette.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
          ],
        ],
      ),
    );
  }

  void _openAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final palette = AppPalette.of(context);
            final email = sheetRef.watch(authControllerProvider).email;
            final themeMode = sheetRef.watch(themeControllerProvider);

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppIcon(
                      AppIcons.user,
                      size: 56,
                      color: palette.ink,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email ?? '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Data tersimpan di perangkat dan disinkronkan ke server.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tema tampilan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Terang'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Gelap'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Sistem'),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (selection) {
                        sheetRef
                            .read(themeControllerProvider.notifier)
                            .setMode(selection.first);
                      },
                    ),
                    const SizedBox(height: 24),
                    ComicButton(
                      text: 'Keluar',
                      color: palette.errorSoft,
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await sheetRef
                            .read(authControllerProvider.notifier)
                            .logout();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _displayName(String? email) {
    if (email == null || email.isEmpty) return 'Sahabat';
    final name = email.split('@').first;
    if (name.isEmpty) return 'Sahabat';
    return name[0].toUpperCase() + name.substring(1);
  }
}
