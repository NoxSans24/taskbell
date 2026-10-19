import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/core/utils/calendar_utils.dart';
import 'package:taskbell_app/data/models/task_model.dart';
import 'package:taskbell_app/logic/providers/task_provider.dart';
import 'package:taskbell_app/presentation/screens/add_edit_task_screen.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';
import 'package:taskbell_app/presentation/widgets/comic_components.dart';

enum _CalendarView { month, week }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  late DateTime _weekAnchor;
  _CalendarView _view = _CalendarView.month;

  @override
  void initState() {
    super.initState();
    final today = dayKey(DateTime.now());
    _visibleMonth = DateTime(today.year, today.month);
    _selectedDay = today;
    _weekAnchor = today;
  }

  void _changePeriod(int delta) {
    if (_view == _CalendarView.month) {
      final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      setState(() {
        _visibleMonth = next;
        if (_selectedDay.year != next.year ||
            _selectedDay.month != next.month) {
          _selectedDay = DateTime(next.year, next.month, 1);
        }
      });
      return;
    }

    setState(() {
      final days = buildWeekDays(_weekAnchor);
      final monday = days.first;
      final nextMonday = DateTime(
        monday.year,
        monday.month,
        monday.day + (7 * delta),
      );
      _weekAnchor = nextMonday;
      final offset = _selectedDay.weekday - DateTime.monday;
      _selectedDay = DateTime(
        nextMonday.year,
        nextMonday.month,
        nextMonday.day + offset,
      );
    });
  }

  void _goToToday() {
    final today = dayKey(DateTime.now());
    setState(() {
      _visibleMonth = DateTime(today.year, today.month);
      _selectedDay = today;
      _weekAnchor = today;
    });
  }

  String _weekRangeLabel() {
    final days = buildWeekDays(_weekAnchor);
    final first = days.first;
    final last = days.last;

    if (first.month == last.month) {
      return '${first.day}–${last.day} ${monthName(first.month)} ${last.year}';
    }

    return '${first.day} ${monthName(first.month)} – '
        '${last.day} ${monthName(last.month)} ${last.year}';
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
            SegmentedButton<_CalendarView>(
              key: const ValueKey('calendar-view-toggle'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _CalendarView.month,
                  label: Text('Bulan'),
                ),
                ButtonSegment(
                  value: _CalendarView.week,
                  label: Text('Minggu'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (selection) {
                setState(() {
                  _view = selection.first;
                  if (_view == _CalendarView.week) {
                    _weekAnchor = _selectedDay;
                  } else {
                    _visibleMonth =
                        DateTime(_selectedDay.year, _selectedDay.month);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            _buildHeader(palette),
            const SizedBox(height: 12),
            if (_view == _CalendarView.month) ...[
              _buildWeekdayHeader(palette),
              const SizedBox(height: 4),
              _buildMonthGrid(palette, tasksByDay, today),
              const SizedBox(height: 24),
              Text(
                '${_selectedDay.day} ${monthName(_selectedDay.month)} '
                '${_selectedDay.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
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
                    child: _buildTaskCard(palette, task),
                  ),
                ),
            ] else
              _buildWeekView(palette, tasksByDay, today),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette palette) {
    final title = _view == _CalendarView.month
        ? '${monthName(_visibleMonth.month)} ${_visibleMonth.year}'
        : _weekRangeLabel();

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        IconButton(
          tooltip: _view == _CalendarView.month
              ? 'Bulan sebelumnya'
              : 'Minggu sebelumnya',
          onPressed: () => _changePeriod(-1),
          icon: AppIcon(AppIcons.chevronLeft, color: palette.ink),
        ),
        IconButton(
          tooltip: _view == _CalendarView.month
              ? 'Bulan berikutnya'
              : 'Minggu berikutnya',
          onPressed: () => _changePeriod(1),
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
      key: const ValueKey('month-grid'),
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

  Widget _buildWeekView(
    AppPalette palette,
    Map<DateTime, List<TaskModel>> tasksByDay,
    DateTime today,
  ) {
    final days = buildWeekDays(_weekAnchor);

    return Column(
      key: const ValueKey('week-view'),
      children: [
        for (final day in days) ...[
          _buildWeekDayCard(palette, day, tasksByDay, today),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildWeekDayCard(
    AppPalette palette,
    DateTime day,
    Map<DateTime, List<TaskModel>> tasksByDay,
    DateTime today,
  ) {
    final dayTasks = tasksByDay[dayKey(day)] ?? const <TaskModel>[];
    final isToday = dayKey(day) == today;
    final canAdd = !dayKey(day).isBefore(today);
    final isSelected = dayKey(day) == dayKey(_selectedDay);

    return ComicCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedDay = dayKey(day)),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          weekdayLabel(day.weekday),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? palette.primary : palette.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${day.day} ${monthName(day.month)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.secondarySoft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: palette.border),
                            ),
                            child: const Text(
                              'Hari ini',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (canAdd)
                IconButton(
                  tooltip: 'Tambah tugas ${day.day}/${day.month}',
                  visualDensity: VisualDensity.compact,
                  icon: AppIcon(AppIcons.plus, size: 18, color: palette.ink),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditTaskScreen(initialDate: day),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (dayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                'Tidak ada tugas.',
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            )
          else
            ...dayTasks.map((task) => _buildTaskRow(palette, task)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(AppPalette palette, TaskModel task) {
    return ComicCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildTaskRow(palette, task),
      ),
    );
  }

  Widget _buildTaskRow(AppPalette palette, TaskModel task) {
    final isCompleted = task.status == TaskStatus.completed;
    final dueDate = task.dueDate!;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddEditTaskScreen(task: task)),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
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
      ),
    );
  }
}
