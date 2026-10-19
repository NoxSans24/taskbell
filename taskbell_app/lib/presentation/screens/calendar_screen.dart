import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/core/utils/calendar_utils.dart';
import 'package:taskbell_app/data/models/task_model.dart';
import 'package:taskbell_app/logic/providers/task_provider.dart';
import 'package:taskbell_app/presentation/screens/add_edit_task_screen.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';
import 'package:taskbell_app/presentation/widgets/comic_components.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = dayKey(DateTime.now());
    _visibleMonth = DateTime(today.year, today.month);
    _selectedDay = today;
  }

  void _changeMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    setState(() {
      _visibleMonth = next;
      if (_selectedDay.year != next.year || _selectedDay.month != next.month) {
        _selectedDay = DateTime(next.year, next.month, 1);
      }
    });
  }

  void _goToToday() {
    final today = dayKey(DateTime.now());
    setState(() {
      _visibleMonth = DateTime(today.year, today.month);
      _selectedDay = today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final tasksAsync = ref.watch(taskListProvider);
    final tasks = tasksAsync.value ?? const <TaskModel>[];

    final tasksByDay = <DateTime, List<TaskModel>>{};
    for (final task in tasks) {
      final dueDate = task.dueDate;
      if (dueDate == null) continue;
      tasksByDay.putIfAbsent(dayKey(dueDate), () => []).add(task);
    }

    final selectedTasks = [...?tasksByDay[dayKey(_selectedDay)]]
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final today = dayKey(DateTime.now());
    final canAddTask = !_selectedDay.isBefore(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agenda',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: canAddTask
          ? FloatingActionButton(
              tooltip: 'Tambah tugas pada tanggal ini',
              backgroundColor: palette.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditTaskScreen(initialDate: _selectedDay),
                  ),
                );
              },
              child: AppIcon(AppIcons.plus, color: palette.onPrimary),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthHeader(palette),
            const SizedBox(height: 12),
            _buildWeekdayHeader(palette),
            const SizedBox(height: 4),
            _buildMonthGrid(palette, tasksByDay, today),
            const SizedBox(height: 24),
            Text(
              '${_selectedDay.day} ${monthName(_selectedDay.month)} '
              '${_selectedDay.year}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (selectedTasks.isEmpty)
              ComicCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tidak ada tugas pada tanggal ini.',
                  style: TextStyle(color: palette.muted),
                ),
              )
            else
              ...selectedTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTaskTile(palette, task),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(AppPalette palette) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${monthName(_visibleMonth.month)} ${_visibleMonth.year}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ),
        IconButton(
          tooltip: 'Bulan sebelumnya',
          onPressed: () => _changeMonth(-1),
          icon: AppIcon(AppIcons.chevronLeft, color: palette.ink),
        ),
        IconButton(
          tooltip: 'Bulan berikutnya',
          onPressed: () => _changeMonth(1),
          icon: AppIcon(AppIcons.chevronRight, color: palette.ink),
        ),
        TextButton(
          onPressed: _goToToday,
          child: Text(
            'Hari ini',
            style: TextStyle(
              color: palette.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(AppPalette palette) {
    return Row(
      children: [
        for (var weekday = DateTime.monday;
            weekday <= DateTime.sunday;
            weekday += 1)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  weekdayLabel(weekday),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthGrid(
    AppPalette palette,
    Map<DateTime, List<TaskModel>> tasksByDay,
    DateTime today,
  ) {
    final weeks = buildMonthGrid(_visibleMonth.year, _visibleMonth.month);

    return Column(
      children: [
        for (final week in weeks)
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: day == null
                      ? const AspectRatio(aspectRatio: 1, child: SizedBox())
                      : _buildDayCell(palette, day, tasksByDay, today),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDayCell(
    AppPalette palette,
    DateTime day,
    Map<DateTime, List<TaskModel>> tasksByDay,
    DateTime today,
  ) {
    final isSelected = dayKey(day) == dayKey(_selectedDay);
    final isToday = dayKey(day) == today;
    final taskCount = tasksByDay[dayKey(day)]?.length ?? 0;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${day.day} ${monthName(day.month)} ${day.year}, $taskCount tugas',
      child: InkWell(
        onTap: () => setState(() => _selectedDay = dayKey(day)),
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? palette.secondary : null,
              borderRadius: BorderRadius.circular(8),
              border:
                  isToday ? Border.all(color: palette.primary, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w600,
                        color: isSelected ? palette.onAccent : palette.ink,
                      ),
                    ),
                  ),
                ),
                if (taskCount > 0)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? palette.onAccent : palette.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTile(AppPalette palette, TaskModel task) {
    final isCompleted = task.status == TaskStatus.completed;
    final dueDate = task.dueDate!;

    return ComicCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddEditTaskScreen(task: task)),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AppIcon(
            isCompleted ? AppIcons.circleCheck : AppIcons.clock,
            color: isCompleted ? palette.success : palette.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${formatTime(dueDate)} • ${task.category}',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
