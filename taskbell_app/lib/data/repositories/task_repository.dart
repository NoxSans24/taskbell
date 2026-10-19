import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:taskbell_app/data/models/task_model.dart';

class TaskRepository {
  static const _uuid = Uuid();
  final Database _db;

  TaskRepository(this._db);

  Future<void> _addMutation(DatabaseExecutor txn, String syncId,
      String entityType, String operation, Map<String, dynamic> payload) async {
    await txn.insert('mutation_queue', {
      'sync_id': syncId,
      'client_mutation_id': _uuid.v4(),
      'entity_type': entityType,
      'operation': operation,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String> _getOrCreateCategorySyncId(
      DatabaseExecutor txn, String categoryName) async {
    final catRows = await txn.query(
      'categories',
      where: 'name = ? AND is_deleted = 0',
      whereArgs: [categoryName],
      limit: 1,
    );
    if (catRows.isNotEmpty) {
      final existingSyncId = catRows.first['sync_id'] as String?;
      if (existingSyncId != null && existingSyncId.isNotEmpty) {
        return existingSyncId;
      }
    }
    final newSyncId = _uuid.v4();
    await txn.insert('categories', {
      'name': categoryName,
      'sync_id': newSyncId,
      'is_deleted': 0,
      'sync_status': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await txn.insert('mutation_queue', {
      'sync_id': newSyncId,
      'client_mutation_id': _uuid.v4(),
      'entity_type': 'category',
      'operation': 'create',
      'payload': jsonEncode({'name': categoryName}),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
    return newSyncId;
  }

  Future<int> createTask(TaskModel task) async {
    return await _db.transaction((txn) async {
      final syncId = task.syncId ?? _uuid.v4();
      final categorySyncId =
          await _getOrCreateCategorySyncId(txn, task.category);

      final taskMap = task.toMap();
      taskMap['sync_id'] = syncId;
      taskMap['sync_status'] = 1;
      final id = await txn.insert('tasks', taskMap);

      final payload = {
        'title': task.title,
        'description': task.description,
        'categoryId': categorySyncId,
        'priority': task.priority.index,
        'status': task.status.index,
        'dueDate': task.dueDate?.toUtc().toIso8601String(),
      };

      await _addMutation(txn, syncId, 'task', 'create', payload);
      return id;
    });
  }

  Future<List<TaskModel>> getAllTasks() async {
    final result = await _db.query('tasks',
        where: 'is_deleted = 0', orderBy: 'due_date ASC');
    return result.map((json) => TaskModel.fromMap(json)).toList();
  }

  Future<int> updateTask(TaskModel task) async {
    return await _db.transaction((txn) async {
      final syncId = task.syncId ?? _uuid.v4();
      final categorySyncId =
          await _getOrCreateCategorySyncId(txn, task.category);

      final taskMap = task.toMap();
      taskMap['sync_id'] = syncId;
      taskMap['sync_status'] = 1;
      final count = await txn.update(
        'tasks',
        taskMap,
        where: 'id = ?',
        whereArgs: [task.id],
      );
      if (count > 0) {
        final payload = {
          'title': task.title,
          'description': task.description,
          'categoryId': categorySyncId,
          'priority': task.priority.index,
          'status': task.status.index,
          'dueDate': task.dueDate?.toUtc().toIso8601String(),
        };
        await _addMutation(txn, syncId, 'task', 'update', payload);
      }
      return count;
    });
  }

  Future<int> deleteTask(int id) async {
    return await _db.transaction((txn) async {
      final tasks = await txn.query('tasks', where: 'id = ?', whereArgs: [id]);
      if (tasks.isEmpty) return 0;
      final task = tasks.first;
      final syncId = (task['sync_id'] as String?) ?? _uuid.v4();

      final count = await txn.update(
        'tasks',
        {
          'is_deleted': 1,
          'sync_status': 1,
          'updated_at': DateTime.now().toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _addMutation(txn, syncId, 'task', 'delete', {});
      return count;
    });
  }
}
