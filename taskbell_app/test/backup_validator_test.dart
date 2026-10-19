import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskbell_app/data/services/backup_validator.dart';

Map<String, dynamic> validBackup() {
  return {
    'format_version': 1,
    'exported_at': '2026-10-20T01:00:00.000Z',
    'tasks': <Map<String, dynamic>>[
      {
        'id': 1,
        'sync_id': '11111111-1111-1111-1111-111111111111',
        'is_deleted': 0,
        'sync_status': 1,
        'updated_at': '2026-10-19T10:00:00.000Z',
        'title': 'Belajar Bab 1',
        'description': 'Ringkasan',
        'category': 'Kuliah',
        'priority': 1,
        'status': 0,
        'due_date': '2026-10-25T10:00:00.000Z',
        'reminder_time': null,
        'created_at': '2026-10-19T10:00:00.000Z',
        'unknown_column': 'abaikan',
      },
    ],
    'categories': <Map<String, dynamic>>[
      {
        'id': 1,
        'sync_id': '22222222-2222-2222-2222-222222222222',
        'name': 'Kuliah',
        'is_deleted': 0,
        'sync_status': 1,
        'updated_at': '2026-10-19T09:00:00.000Z',
      },
    ],
  };
}

String encode(Map<String, dynamic> value) => jsonEncode(value);

void main() {
  group('Backup validator', () {
    test('menerima backup valid dan membuang kolom tak dikenal', () {
      final data = parseBackupData(encode(validBackup()));

      expect(data.taskCount, 1);
      expect(data.categoryCount, 1);
      expect(data.exportedAt, isNotNull);
      expect(data.tasks.first.containsKey('unknown_column'), isFalse);
      expect(data.tasks.first['title'], 'Belajar Bab 1');
      expect(data.tasks.first['due_date'], '2026-10-25T10:00:00.000Z');
    });

    test('memaksa sync_status tugas menjadi 0 setelah restore', () {
      final data = parseBackupData(encode(validBackup()));
      expect(data.tasks.first['sync_status'], 0);
    });

    test('menolak format_version yang tidak didukung', () {
      final backup = validBackup()..['format_version'] = 99;

      expect(
        () => parseBackupData(encode(backup)),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('menolak JSON yang rusak', () {
      expect(
        () => parseBackupData('{bukan json'),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('menolak tugas tanpa judul', () {
      final backup = validBackup();
      (backup['tasks'] as List).first.remove('title');

      expect(
        () => parseBackupData(encode(backup)),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('menolak prioritas di luar rentang', () {
      final backup = validBackup();
      (backup['tasks'] as List).first['priority'] = 5;

      expect(
        () => parseBackupData(encode(backup)),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('menolak sync_id duplikat antar tugas', () {
      final backup = validBackup();
      final tasks = backup['tasks'] as List;
      tasks.add(Map<String, dynamic>.from(tasks.first as Map));

      expect(
        () => parseBackupData(encode(backup)),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('menolak tugas dengan kategori yang tidak ada di backup', () {
      final backup = validBackup();
      (backup['tasks'] as List).first['category'] = 'Tidak Ada';

      expect(
        () => parseBackupData(encode(backup)),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('menolak nama kategori duplikat', () {
      final backup = validBackup();
      final categories = backup['categories'] as List<Map<String, dynamic>>;
      categories.add(Map<String, dynamic>.from(categories.first));

      expect(
        () => parseBackupData(encode(backup)),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('menolak daftar tugas yang hilang', () {
      final backup = validBackup()..remove('tasks');

      expect(
        () => parseBackupData(encode(backup)),
        throwsA(isA<BackupValidationException>()),
      );
    });
  });
}
