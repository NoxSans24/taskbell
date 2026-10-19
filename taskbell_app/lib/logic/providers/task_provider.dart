import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/data/models/task_model.dart';
import 'package:taskbell_app/data/repositories/task_repository.dart';
import 'package:taskbell_app/data/services/notification_service.dart';
import 'package:taskbell_app/logic/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, AsyncValue<List<TaskModel>>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repository);
});

class TaskListNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository? _repository;
  final NotificationService _notificationService = NotificationService();

  TaskListNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    if (_repository == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository!.getAllTasks();
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTask(TaskModel task) async {
    if (_repository == null) return;

    try {
      // 1. Simpan tugas ke database terlebih dahulu.
      final id = await _repository!.createTask(task);

      // 2. Perbarui daftar tugas agar tugas langsung terlihat.
      await fetchTasks();

      // 3. Jadwalkan notifikasi secara terpisah (hanya untuk tugas belum selesai dan tanggal di masa mendatang).
      if (task.status != TaskStatus.completed &&
          task.dueDate != null &&
          task.dueDate!.isAfter(DateTime.now())) {
        try {
          await _notificationService.scheduleNotification(
            id: id,
            title: 'Pengingat Tugas',
            body: task.title,
            scheduledDate: task.dueDate!,
          );
        } catch (e, stack) {
          debugPrint('Gagal menjadwalkan notifikasi: $e');
          debugPrintStack(stackTrace: stack);
        }
      }
    } catch (e, stack) {
      debugPrint('Gagal menyimpan tugas: $e');
      debugPrintStack(stackTrace: stack);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    if (_repository == null) return;
    final currentTasks = state.value ?? [];
    try {
      await _repository!.updateTask(task);

      // Jika tugas sudah selesai atau tanggal lewat/kosong, batalkan alarm pengingat.
      if (task.status != TaskStatus.completed &&
          task.dueDate != null &&
          task.dueDate!.isAfter(DateTime.now())) {
        try {
          await _notificationService.scheduleNotification(
            id: task.id!,
            title: "Pengingat Tugas",
            body: task.title,
            scheduledDate: task.dueDate!,
          );
        } catch (e) {
          debugPrint('Gagal menjadwalkan notifikasi: $e');
        }
      } else {
        if (task.id != null) {
          try {
            await _notificationService.cancelNotification(task.id!);
          } catch (e) {
            debugPrint('Gagal membatalkan notifikasi: $e');
          }
        }
      }

      state = AsyncValue.data(
          [for (final t in currentTasks) t.id == task.id ? task : t]);
    } catch (e) {
      debugPrint('Gagal mengupdate tugas: $e');
      state = AsyncValue.data(currentTasks);
      rethrow;
    }
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    try {
      final updatedTask = task.copyWith(
        status: task.status == TaskStatus.completed
            ? TaskStatus.pending
            : TaskStatus.completed,
      );
      await updateTask(updatedTask);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTask(int id) async {
    if (_repository == null) return;
    final currentTasks = state.value ?? [];
    try {
      await _repository!.deleteTask(id);
      try {
        await _notificationService.cancelNotification(id);
      } catch (e) {
        debugPrint('Gagal membatalkan notifikasi saat menghapus: $e');
      }
      state = AsyncValue.data([
        for (final t in currentTasks)
          if (t.id != id) t
      ]);
    } catch (e) {
      debugPrint('Gagal menghapus tugas: $e');
      state = AsyncValue.data(currentTasks);
      rethrow;
    }
  }
}

final taskStatsProvider = Provider<Map<String, int>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  return tasksAsync.maybeWhen(
    data: (tasks) {
      final total = tasks.length;
      final completed =
          tasks.where((t) => t.status == TaskStatus.completed).length;
      final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
      final overdue = tasks
          .where((t) =>
              t.status == TaskStatus.pending &&
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime.now()))
          .length;

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'overdue': overdue,
      };
    },
    orElse: () => {'total': 0, 'completed': 0, 'pending': 0, 'overdue': 0},
  );
});
