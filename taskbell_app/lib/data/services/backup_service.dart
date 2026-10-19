import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:taskbell_app/data/services/backup_crypto.dart';
import 'package:taskbell_app/data/services/backup_validator.dart';
import 'package:taskbell_app/data/services/local_database.dart';
import 'package:uuid/uuid.dart';

class BackupService {
  static const _uuid = Uuid();
  static const int _maxFileBytes = 20 * 1024 * 1024;

  final String userId;

  BackupService(this.userId);

  String get fileName => 'taskbell_backup_$userId.json';

  Future<Database> _database() {
    return LocalDatabase.instance.getDatabaseForUser(userId);
  }

  Future<Directory> _backupDirectory() async {
    return await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
  }

  Future<String> backupPath() async {
    final directory = await _backupDirectory();
    return '${directory.path}/$fileName';
  }

  Future<String> exportBackup({String? password}) async {
    final db = await _database();
    final tasks = await db.query(
      'tasks',
      where: 'is_deleted = 0',
      orderBy: 'created_at ASC',
    );
    final categories = await db.query('categories');

    final payload = {
      'format_version': backupFormatVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'app': 'TaskBell',
      'tasks': tasks,
      'categories': categories,
    };

    final plainJson = jsonEncode(payload);
    final output = password == null || password.isEmpty
        ? plainJson
        : await encryptBackup(plainJson: plainJson, password: password);

    final path = await backupPath();
    final file = File(path);
    final temporary = File('$path.tmp');

    // Tulis ke file sementara lalu ganti, agar backup lama tidak rusak
    // setengah jalan bila proses berhenti.
    await temporary.writeAsString(output, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await temporary.rename(path);

    return path;
  }

  /// True bila file backup dienkripsi dengan kata sandi.
  Future<bool> isEncrypted(String filePath) async {
    final raw = await _readRaw(filePath);
    return tryParseEncryptedEnvelope(raw) != null;
  }

  Future<BackupData> readBackup(
    String filePath, {
    String? password,
  }) async {
    final raw = await _readRaw(filePath);

    if (tryParseEncryptedEnvelope(raw) != null) {
      if (password == null || password.isEmpty) {
        throw const BackupValidationException(
          'Backup ini terenkripsi. Masukkan kata sandi.',
        );
      }

      final plainJson = await decryptBackup(raw: raw, password: password);
      return parseBackupData(plainJson);
    }

    return parseBackupData(raw);
  }

  Future<String> _readRaw(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw const BackupValidationException(
        'File backup tidak ditemukan di perangkat.',
      );
    }

    if (await file.length() > _maxFileBytes) {
      throw const BackupValidationException(
        'Ukuran file backup terlalu besar.',
      );
    }

    return file.readAsString();
  }

  /// Mengganti seluruh data lokal dengan isi backup yang sudah tervalidasi.
  ///
  /// Antrean mutasi dan cursor sinkronisasi dikosongkan agar data hasil
  /// restore tidak terkirim ulang sebagai mutasi baru.
  Future<void> importBackup(String filePath, {String? password}) async {
    final data = await readBackup(filePath, password: password);
    final db = await _database();

    await db.transaction((txn) async {
      await txn.delete('tasks');
      await txn.delete('categories');
      await txn.delete('mutation_queue');
      await txn.delete('sync_state');

      for (final category in data.categories) {
        await txn.insert('categories', _withSyncId(category));
      }

      for (final task in data.tasks) {
        await txn.insert('tasks', _withSyncId(task));
      }

      await txn.insert('sync_state', {'last_sequence': '0'});
    });
  }

  Map<String, Object?> _withSyncId(Map<String, Object?> row) {
    final syncId = row['sync_id'];
    if (syncId is String && syncId.isNotEmpty) return row;
    return {...row, 'sync_id': _uuid.v4()};
  }
}
