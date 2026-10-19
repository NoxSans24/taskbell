import 'dart:convert';

/// Kesalahan yang aman ditampilkan ke pengguna saat file backup tidak valid.
class BackupValidationException implements Exception {
  final String message;

  const BackupValidationException(this.message);

  @override
  String toString() => message;
}

class BackupData {
  final List<Map<String, Object?>> tasks;
  final List<Map<String, Object?>> categories;
  final DateTime? exportedAt;

  const BackupData({
    required this.tasks,
    required this.categories,
    this.exportedAt,
  });

  int get taskCount => tasks.length;
  int get categoryCount => categories.length;
}

const int backupFormatVersion = 1;
const int maxBackupTasks = 50000;
const int maxBackupCategories = 5000;

/// Memvalidasi isi file backup dan mengembalikan baris yang sudah dibersihkan.
///
/// Hanya kolom yang dikenal yang diteruskan ke database, sehingga file yang
/// dimodifikasi tidak dapat menyisipkan nama kolom sembarangan.
BackupData parseBackupData(String raw) {
  dynamic decoded;

  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    throw const BackupValidationException('File backup bukan JSON yang valid.');
  }

  if (decoded is! Map<String, dynamic>) {
    throw const BackupValidationException(
        'Struktur file backup tidak dikenali.');
  }

  final version = decoded['format_version'];
  if (version is! int || version != backupFormatVersion) {
    throw BackupValidationException(
      'Versi backup tidak didukung (format_version: $version).',
    );
  }

  final rawTasks = decoded['tasks'];
  if (rawTasks is! List) {
    throw const BackupValidationException(
      'Daftar tugas (tasks) tidak ditemukan di file backup.',
    );
  }
  if (rawTasks.length > maxBackupTasks) {
    throw const BackupValidationException(
      'Jumlah tugas di backup melebihi batas.',
    );
  }

  final rawCategories = decoded['categories'];
  if (rawCategories != null && rawCategories is! List) {
    throw const BackupValidationException(
      'Daftar kategori (categories) tidak valid.',
    );
  }
  final categoryList = (rawCategories as List?) ?? const [];
  if (categoryList.length > maxBackupCategories) {
    throw const BackupValidationException(
      'Jumlah kategori di backup melebihi batas.',
    );
  }

  final categories = <Map<String, Object?>>[];
  final categoryNames = <String>{};
  final categoryIds = <int>{};

  for (var i = 0; i < categoryList.length; i += 1) {
    final rawCategory = categoryList[i];
    if (rawCategory is! Map) {
      throw BackupValidationException('Kategori #${i + 1} bukan objek.');
    }

    final category = Map<String, dynamic>.from(rawCategory);
    final label = 'Kategori #${i + 1}';
    final name = _requiredString(category['name'], '$label nama', max: 100);

    if (!categoryNames.add(name)) {
      throw BackupValidationException(
        'Nama kategori "$name" muncul lebih dari sekali.',
      );
    }

    final id = _optionalId(category['id'], '$label id');
    if (id != null && !categoryIds.add(id)) {
      throw BackupValidationException('$label memakai id duplikat.');
    }

    categories.add({
      if (id != null) 'id': id,
      'sync_id': _optionalSyncId(category['sync_id']),
      'name': name,
      'is_deleted': _flag(category['is_deleted'], '$label is_deleted'),
      'sync_status': _flag(category['sync_status'], '$label sync_status'),
      'updated_at':
          _optionalDate(category['updated_at'], '$label updated_at') ??
              DateTime.now().toUtc().toIso8601String(),
    });
  }

  final tasks = <Map<String, Object?>>[];
  final taskIds = <int>{};
  final taskSyncIds = <String>{};

  for (var i = 0; i < rawTasks.length; i += 1) {
    final rawTask = rawTasks[i];
    if (rawTask is! Map) {
      throw BackupValidationException('Tugas #${i + 1} bukan objek.');
    }

    final task = Map<String, dynamic>.from(rawTask);
    final label = 'Tugas #${i + 1}';
    final title = _requiredString(task['title'], '$label judul', max: 250);
    final category =
        _requiredString(task['category'], '$label kategori', max: 100);

    if (!categoryNames.contains(category)) {
      throw BackupValidationException(
        '$label memakai kategori "$category" yang tidak ada di backup.',
      );
    }

    final priority =
        _requiredInt(task['priority'], '$label prioritas', min: 0, max: 2);
    final status =
        _requiredInt(task['status'], '$label status', min: 0, max: 1);
    final createdAt = _requiredDate(task['created_at'], '$label created_at');
    final description =
        _optionalString(task['description'], '$label deskripsi', max: 5000);

    final id = _optionalId(task['id'], '$label id');
    if (id != null && !taskIds.add(id)) {
      throw BackupValidationException('$label memakai id duplikat.');
    }

    final syncId = _optionalSyncId(task['sync_id']);
    if (syncId != null && !taskSyncIds.add(syncId)) {
      throw BackupValidationException(
        '$label memakai sync_id duplikat.',
      );
    }

    tasks.add({
      if (id != null) 'id': id,
      'sync_id': syncId,
      'is_deleted': _flag(task['is_deleted'], '$label is_deleted'),
      'sync_status': 0,
      'updated_at': createdAt,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'due_date': _optionalDate(task['due_date'], '$label due_date'),
      'reminder_time':
          _optionalDate(task['reminder_time'], '$label reminder_time'),
      'created_at': createdAt,
    });
  }

  DateTime? exportedAt;
  final rawExportedAt = decoded['exported_at'];
  if (rawExportedAt != null) {
    exportedAt = DateTime.tryParse(rawExportedAt.toString());
  }

  return BackupData(
    tasks: tasks,
    categories: categories,
    exportedAt: exportedAt,
  );
}

String _requiredString(dynamic value, String label, {required int max}) {
  if (value is! String || value.trim().isEmpty) {
    throw BackupValidationException('$label wajib berupa teks.');
  }

  final text = value.trim();
  if (text.length > max) {
    throw BackupValidationException('$label melebihi $max karakter.');
  }

  return text;
}

String? _optionalString(dynamic value, String label, {required int max}) {
  if (value == null) return null;
  if (value is! String) {
    throw BackupValidationException('$label harus berupa teks.');
  }
  if (value.length > max) {
    throw BackupValidationException('$label melebihi $max karakter.');
  }
  return value;
}

int _requiredInt(dynamic value, String label,
    {required int min, required int max}) {
  final number = _asInt(value);
  if (number == null || number < min || number > max) {
    throw BackupValidationException('$label di luar rentang yang didukung.');
  }
  return number;
}

int _flag(dynamic value, String label) {
  if (value == null) return 0;
  if (value is bool) return value ? 1 : 0;

  final number = _asInt(value);
  if (number == null || (number != 0 && number != 1)) {
    throw BackupValidationException('$label harus 0 atau 1.');
  }
  return number;
}

int? _optionalId(dynamic value, String label) {
  if (value == null) return null;
  final number = _asInt(value);
  if (number == null || number < 0) {
    throw BackupValidationException('$label tidak valid.');
  }
  return number;
}

String? _optionalSyncId(dynamic value) {
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty || value.length > 100) {
    throw const BackupValidationException('sync_id tidak valid.');
  }
  return value.trim();
}

String _requiredDate(dynamic value, String label) {
  final parsed = _optionalDate(value, label);
  if (parsed == null) {
    throw BackupValidationException('$label wajib berisi tanggal.');
  }
  return parsed;
}

String? _optionalDate(dynamic value, String label) {
  if (value == null) return null;
  if (value is! String) {
    throw BackupValidationException('$label harus berupa teks tanggal.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw BackupValidationException('$label bukan tanggal yang valid.');
  }
  return value;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  return null;
}
