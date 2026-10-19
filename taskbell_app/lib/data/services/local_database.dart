import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

const String _sqliteHeader = 'SQLite format 3\u0000';
const int _databaseVersion = 5;

/// Mengembalikan true bila 16 byte pertama adalah header database SQLite
/// biasa (belum terenkripsi).
bool isPlaintextSqliteHeader(List<int> headerBytes) {
  if (headerBytes.length < _sqliteHeader.length) return false;

  for (var i = 0; i < _sqliteHeader.length; i += 1) {
    if (headerBytes[i] != _sqliteHeader.codeUnitAt(i)) return false;
  }

  return true;
}

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static const _uuid = Uuid();
  static const _keyPrefix = 'taskbell_db_key_';

  final Map<String, Database> _userDatabases = {};
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  LocalDatabase._init();

  Future<Database> getDatabaseForUser(String userId) async {
    final sanitizedUserId = _sanitize(userId);

    final cached = _userDatabases[sanitizedUserId];
    if (cached != null) return cached;

    final dbPath = join(
      await getDatabasesPath(),
      'taskbell_$sanitizedUserId.db',
    );
    final key = await _loadOrCreateKey(sanitizedUserId);

    await _recoverInterruptedMigration(dbPath);

    if (await _isPlaintextDatabase(dbPath)) {
      await _migratePlaintextDatabase(dbPath, key);
    }

    final db = await openDatabase(
      dbPath,
      password: key,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    _userDatabases[sanitizedUserId] = db;
    return db;
  }

  Future<void> closeDatabaseForUser(String userId) async {
    final sanitizedUserId = _sanitize(userId);

    final db = _userDatabases.remove(sanitizedUserId);
    await db?.close();
  }

  String _sanitize(String userId) {
    final sanitized = userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    if (sanitized.isEmpty) {
      throw ArgumentError('Invalid userId: $userId');
    }

    return sanitized;
  }

  Future<String> _loadOrCreateKey(String sanitizedUserId) async {
    final storageKey = '$_keyPrefix$sanitizedUserId';
    final existing = await _secureStorage.read(key: storageKey);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = base64UrlEncode(bytes);

    await _secureStorage.write(key: storageKey, value: key);
    return key;
  }

  Future<bool> _isPlaintextDatabase(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;

    final raf = await file.open();
    try {
      return isPlaintextSqliteHeader(await raf.read(16));
    } finally {
      await raf.close();
    }
  }

  /// Jika proses migrasi sebelumnya terputus, file `.legacy` masih ada.
  /// Pulihkan file itu sebagai sumber dan buang hasil yang belum lengkap.
  Future<void> _recoverInterruptedMigration(String path) async {
    final legacy = File('$path.legacy');
    if (!await legacy.exists()) return;

    final current = File(path);
    if (await current.exists()) {
      await current.delete();
    }

    await legacy.rename(path);
  }

  /// Menyalin database plaintext lama ke database terenkripsi.
  ///
  /// File asli diganti nama menjadi `.legacy` sampai proses selesai; bila
  /// terjadi kegagalan, file asli dikembalikan.
  Future<void> _migratePlaintextDatabase(String path, String key) async {
    final legacyPath = '$path.legacy';
    final legacyFile = File(legacyPath);
    final targetFile = File(path);

    if (await legacyFile.exists()) {
      await legacyFile.delete();
    }
    await targetFile.rename(legacyPath);

    Database? plain;
    Database? encrypted;

    try {
      plain = await openDatabase(legacyPath);

      final categories = await plain.query('categories');
      final tasks = await plain.query('tasks');
      final mutations = await plain.query('mutation_queue');
      final syncState = await plain.query('sync_state');

      encrypted = await openDatabase(
        path,
        password: key,
        version: _databaseVersion,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );

      await encrypted.transaction((txn) async {
        for (final row in categories) {
          await txn.insert('categories', row);
        }
        for (final row in tasks) {
          await txn.insert('tasks', row);
        }
        for (final row in mutations) {
          await txn.insert('mutation_queue', row);
        }
        for (final row in syncState) {
          await txn.insert('sync_state', row);
        }
      });

      await encrypted.close();
      encrypted = null;
      await plain.close();
      plain = null;

      await legacyFile.delete();
    } catch (_) {
      if (plain != null) {
        try {
          await plain.close();
        } catch (_) {
          // Abaikan kegagalan penutupan saat pemulihan.
        }
      }
      if (encrypted != null) {
        try {
          await encrypted.close();
        } catch (_) {
          // Abaikan kegagalan penutupan saat pemulihan.
        }
      }

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      if (await legacyFile.exists()) {
        await legacyFile.rename(path);
      }

      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN sync_id TEXT');
      await db
          .execute('ALTER TABLE tasks ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE tasks ADD COLUMN updated_at TEXT');

      await db.execute('ALTER TABLE categories ADD COLUMN sync_id TEXT');
      await db.execute(
          'ALTER TABLE categories ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE categories ADD COLUMN updated_at TEXT');
    }

    if (oldVersion < 3) {
      final tasks = await db.query('tasks');
      for (final task in tasks) {
        if (task['sync_id'] == null) {
          await db.update('tasks', {'sync_id': _uuid.v4()},
              where: 'id = ?', whereArgs: [task['id']]);
        }
      }

      final categories = await db.query('categories');
      for (final cat in categories) {
        if (cat['sync_id'] == null) {
          await db.update('categories', {'sync_id': _uuid.v4()},
              where: 'id = ?', whereArgs: [cat['id']]);
        }
      }
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mutation_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sync_id TEXT NOT NULL,
          client_mutation_id TEXT NOT NULL,
          entity_type TEXT NOT NULL,
          operation TEXT NOT NULL,
          payload TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          attempts INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      final queueInfo = await db.rawQuery('PRAGMA table_info(mutation_queue)');
      final hasClientMutationId =
          queueInfo.any((c) => c['name'] == 'client_mutation_id');
      if (!hasClientMutationId) {
        await db.execute(
            'ALTER TABLE mutation_queue ADD COLUMN client_mutation_id TEXT');
      }

      final taskCols = await db.rawQuery('PRAGMA table_info(tasks)');
      if (!taskCols.any((c) => c['name'] == 'sync_status')) {
        await db.execute(
            'ALTER TABLE tasks ADD COLUMN sync_status INTEGER DEFAULT 0');
      }

      final catCols = await db.rawQuery('PRAGMA table_info(categories)');
      if (!catCols.any((c) => c['name'] == 'sync_status')) {
        await db.execute(
            'ALTER TABLE categories ADD COLUMN sync_status INTEGER DEFAULT 0');
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_state (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          last_sequence TEXT DEFAULT '0'
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE,
        is_deleted INTEGER DEFAULT 0,
        sync_status INTEGER DEFAULT 0,
        updated_at TEXT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        priority INTEGER NOT NULL,
        status INTEGER NOT NULL,
        due_date TEXT,
        reminder_time TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT UNIQUE,
        is_deleted INTEGER DEFAULT 0,
        sync_status INTEGER DEFAULT 0,
        updated_at TEXT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE mutation_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT NOT NULL,
        client_mutation_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        attempts INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_state (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_sequence TEXT DEFAULT '0'
      )
    ''');

    final defaultCategories = ['Kuliah', 'Pribadi', 'Kerja'];
    for (final name in defaultCategories) {
      final syncId = _uuid.v4();
      await db.insert('categories', {
        'name': name,
        'sync_id': syncId,
        'is_deleted': 0,
        'sync_status': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('mutation_queue', {
        'sync_id': syncId,
        'client_mutation_id': _uuid.v4(),
        'entity_type': 'category',
        'operation': 'create',
        'payload': jsonEncode({'name': name}),
        'status': 'pending',
        'attempts': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
