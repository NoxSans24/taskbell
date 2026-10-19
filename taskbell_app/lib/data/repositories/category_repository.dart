import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:taskbell_app/data/models/category_model.dart';
import 'package:uuid/uuid.dart';

abstract class CategoryStore {
  Future<List<CategoryModel>> getAllCategories();

  Future<int> createCategory(String name);

  Future<int> updateCategory(int id, String name);

  Future<int> deleteCategory(int id);

  Future<int> countTasksForCategory(String name);
}

class CategoryRepository implements CategoryStore {
  static const _uuid = Uuid();

  final Database _db;

  CategoryRepository(this._db);

  Future<void> _addMutation(
    DatabaseExecutor txn, {
    required String syncId,
    required String operation,
    required String name,
  }) async {
    await txn.insert('mutation_queue', {
      'sync_id': syncId,
      'client_mutation_id': _uuid.v4(),
      'entity_type': 'category',
      'operation': operation,
      'payload': jsonEncode({'name': name}),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    final rows = await _db.query(
      'categories',
      where: 'is_deleted = 0',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(CategoryModel.fromMap).toList();
  }

  @override
  Future<int> countTasksForCategory(String name) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM tasks '
      'WHERE is_deleted = 0 AND category = ?',
      [name],
    );

    return (rows.first['total'] as int?) ?? 0;
  }

  @override
  Future<int> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Nama kategori wajib diisi.');
    }

    return _db.transaction((txn) async {
      final syncId = _uuid.v4();

      final id = await txn.insert('categories', {
        'name': trimmed,
        'sync_id': syncId,
        'is_deleted': 0,
        'sync_status': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _addMutation(
        txn,
        syncId: syncId,
        operation: 'create',
        name: trimmed,
      );

      return id;
    });
  }

  @override
  Future<int> updateCategory(int id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Nama kategori wajib diisi.');
    }

    return _db.transaction((txn) async {
      final rows = await txn.query(
        'categories',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) return 0;

      final old = rows.first;
      final oldName = old['name'] as String;
      final syncId = old['sync_id'] as String? ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final count = await txn.update(
        'categories',
        {'name': trimmed, 'sync_id': syncId, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count > 0) {
        // Nama kategori didenormalisasi di tabel tugas; ikut diperbarui agar
        // filter dan tampilan tidak menunjuk nama lama.
        if (oldName != trimmed) {
          await txn.update(
            'tasks',
            {'category': trimmed},
            where: 'category = ?',
            whereArgs: [oldName],
          );
        }

        await _addMutation(
          txn,
          syncId: syncId,
          operation: 'update',
          name: trimmed,
        );
      }

      return count;
    });
  }

  @override
  Future<int> deleteCategory(int id) async {
    return _db.transaction((txn) async {
      final rows = await txn.query(
        'categories',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) return 0;

      final category = rows.first;
      final syncId = category['sync_id'] as String? ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final count = await txn.update(
        'categories',
        {'sync_id': syncId, 'is_deleted': 1, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count > 0) {
        await _addMutation(
          txn,
          syncId: syncId,
          operation: 'delete',
          name: category['name'] as String,
        );
      }

      return count;
    });
  }
}
