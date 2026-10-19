import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:taskbell_app/data/api/api_client.dart';

class SyncService {
  final Database _db;
  final ApiClient _apiClient;
  bool _isSyncing = false;

  SyncService(this._db, this._apiClient);

  Future<void> pushMutations() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final mutations = await _db.query(
        'mutation_queue',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );

      if (mutations.isEmpty) return;

      final List<Map<String, dynamic>> payload = mutations.map((m) {
        return {
          'clientMutationId': m['client_mutation_id'],
          'syncId': m['sync_id'],
          'entityType': m['entity_type'],
          'operation': m['operation'],
          'payload': jsonDecode(m['payload'] as String),
        };
      }).toList();

      final results = await _apiClient.pushMutations(payload);

      await _db.transaction((txn) async {
        for (final res in results) {
          final clientMutationId = res['clientMutationId'];
          final status = res['status'];

          if (status == 'success' || status == 'already_processed') {
            final mutRecord = await txn.query(
              'mutation_queue',
              where: 'client_mutation_id = ?',
              whereArgs: [clientMutationId],
            );

            if (mutRecord.isNotEmpty) {
              final syncId = mutRecord.first['sync_id'] as String;
              final entityType = mutRecord.first['entity_type'] as String;

              final remaining = await txn.query(
                'mutation_queue',
                where: 'sync_id = ? AND client_mutation_id != ? AND status = ?',
                whereArgs: [syncId, clientMutationId, 'pending'],
              );

              if (remaining.isEmpty) {
                await txn.update(
                  entityType == 'task' ? 'tasks' : 'categories',
                  {'sync_status': 0},
                  where: 'sync_id = ?',
                  whereArgs: [syncId],
                );
              }
            }

            await txn.delete(
              'mutation_queue',
              where: 'client_mutation_id = ?',
              whereArgs: [clientMutationId],
            );
          } else if (status == 'failed') {
            final mutRecord = await txn.query(
              'mutation_queue',
              where: 'client_mutation_id = ?',
              whereArgs: [clientMutationId],
            );

            if (mutRecord.isNotEmpty) {
              final currentAttempts =
                  (mutRecord.first['attempts'] as int?) ?? 0;

              await txn.update(
                'mutation_queue',
                {
                  'status':
                      currentAttempts >= 2 ? 'failed_permanent' : 'pending',
                  'attempts': currentAttempts + 1,
                },
                where: 'client_mutation_id = ?',
                whereArgs: [clientMutationId],
              );
            }
          }
        }
      });
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> pullChanges() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final stateResult = await _db.query('sync_state', limit: 1);
      String cursor = '0';
      if (stateResult.isNotEmpty) {
        cursor = stateResult.first['last_sequence']?.toString() ?? '0';
      }

      bool hasMore = true;
      while (hasMore) {
        final body = await _apiClient.pullChanges(cursor, 50);
        final changes = body['changes'] as List<dynamic>;
        final nextCursor = body['nextCursor'];

        if (changes.isEmpty) {
          hasMore = false;
          break;
        }

        await _db.transaction((txn) async {
          for (final change in changes) {
            final seq = change['sequence'].toString();
            final entityType = change['entityType'];
            final operation = change['operation'];
            final syncId = change['syncId'];
            final payload = change['payload'] is String
                ? jsonDecode(change['payload'])
                : change['payload'];

            final tableName = entityType == 'task' ? 'tasks' : 'categories';

            // Perubahan lokal yang belum terkirim diprioritaskan.
            final pendingMutations = await txn.query(
              'mutation_queue',
              where: 'sync_id = ? AND status = ?',
              whereArgs: [syncId, 'pending'],
            );

            if (pendingMutations.isNotEmpty) {
              cursor = seq;
              continue;
            }

            if (operation == 'delete' || (payload['isDeleted'] == true)) {
              await txn.delete(
                tableName,
                where: 'sync_id = ?',
                whereArgs: [syncId],
              );
            } else if (tableName == 'tasks') {
              final categorySyncId = payload['categoryId'];
              final catQuery = await txn.query(
                'categories',
                where: 'sync_id = ?',
                whereArgs: [categorySyncId],
              );

              if (catQuery.isEmpty) {
                cursor = seq;
                continue;
              }

              final taskData = {
                'sync_id': syncId,
                'title': payload['title'],
                'description': payload['description'],
                'priority': payload['priority'],
                'status': payload['status'],
                'due_date': payload['dueDate'],
                'category': catQuery.first['name'],
                'is_deleted': 0,
                'sync_status': 0,
                'updated_at': DateTime.now().toIso8601String(),
                'created_at':
                    payload['createdAt'] ?? DateTime.now().toIso8601String(),
              };

              final existing = await txn.query(
                tableName,
                where: 'sync_id = ?',
                whereArgs: [syncId],
              );

              if (existing.isEmpty) {
                await txn.insert(tableName, taskData);
              } else {
                await txn.update(
                  tableName,
                  taskData,
                  where: 'sync_id = ?',
                  whereArgs: [syncId],
                );
              }
            } else {
              final catData = {
                'sync_id': syncId,
                'name': payload['name'],
                'is_deleted': 0,
                'sync_status': 0,
                'updated_at': DateTime.now().toIso8601String(),
              };

              final existing = await txn.query(
                tableName,
                where: 'sync_id = ?',
                whereArgs: [syncId],
              );

              if (existing.isEmpty) {
                await txn.insert(tableName, catData);
              } else {
                await txn.update(
                  tableName,
                  catData,
                  where: 'sync_id = ?',
                  whereArgs: [syncId],
                );
              }
            }

            cursor = seq;
          }

          if (stateResult.isEmpty) {
            await txn.insert('sync_state', {'last_sequence': cursor});
          } else {
            await txn.update('sync_state', {'last_sequence': cursor});
          }
        });

        if (nextCursor == null || nextCursor == cursor) {
          hasMore = false;
        } else {
          cursor = nextCursor.toString();
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
