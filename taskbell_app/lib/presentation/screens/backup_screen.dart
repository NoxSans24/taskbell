import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/services/backup_service.dart';
import 'package:taskbell_app/data/services/backup_validator.dart';
import 'package:taskbell_app/logic/providers/auth_provider.dart';
import 'package:taskbell_app/presentation/widgets/comic_components.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;

  Future<void> _handleBackup() async {
    final userId = ref.read(authUserIdProvider);

    if (userId == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = BackupService(userId);
      final path = await service.exportBackup();
      final backup = await service.readBackup(path);

      if (!mounted) return;
      _showMessage(
        'Backup tersimpan: ${path.split('/').last} '
        '(${backup.taskCount} tugas, ${backup.categoryCount} kategori).',
      );
    } on BackupValidationException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      debugPrint('Backup error: $error');
      _showMessage('Backup gagal dibuat. Periksa ruang penyimpanan.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestoreLast() async {
    final userId = ref.read(authUserIdProvider);

    if (userId == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = BackupService(userId);
      final path = await service.backupPath();
      await _restoreFromPath(service, path, userId);
    } on BackupValidationException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      debugPrint('Restore error: $error');
      _showMessage('Restore gagal. File backup tidak dapat diterapkan.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestoreFromFile() async {
    final userId = ref.read(authUserIdProvider);

    if (userId == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      const typeGroup = XTypeGroup(
        label: 'Backup JSON',
        extensions: <String>['json'],
        mimeTypes: <String>['application/json'],
      );
      final file = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[typeGroup],
      );

      if (file == null) return;

      final service = BackupService(userId);
      await _restoreFromPath(service, file.path, userId);
    } on BackupValidationException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      debugPrint('Restore error: $error');
      _showMessage('Restore gagal. File backup tidak dapat diterapkan.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreFromPath(
    BackupService service,
    String path,
    String userId,
  ) async {
    final backup = await service.readBackup(path);

    if (!mounted) return;

    final confirmed = await _confirmRestore(backup);
    if (confirmed != true) return;

    await service.importBackup(path);

    if (!mounted) return;
    _showMessage('Restore berhasil: ${backup.taskCount} tugas dipulihkan.');
    ref.invalidate(databaseProvider(userId));
  }

  Future<bool?> _confirmRestore(BackupData backup) {
    final exportedAt = backup.exportedAt;
    final exportedLabel = exportedAt == null
        ? 'tanggal tidak tercatat'
        : DateFormat('dd MMM yyyy, HH:mm').format(exportedAt.toLocal());

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Restore'),
        content: Text(
          'Backup berisi ${backup.taskCount} tugas dan '
          '${backup.categoryCount} kategori ($exportedLabel).\n\n'
          'Seluruh tugas dan kategori saat ini akan diganti. '
          'Pastikan kamu sudah membuat backup terbaru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ComicButton(
              text: _isLoading ? 'Memproses...' : 'Buat Backup (.json)',
              onPressed: _isLoading ? () {} : _handleBackup,
            ),
            const SizedBox(height: 16),
            ComicButton(
              text: _isLoading ? 'Memproses...' : 'Pulihkan dari File...',
              onPressed: _isLoading ? () {} : _handleRestoreFromFile,
            ),
            const SizedBox(height: 12),
            ComicButton(
              text: _isLoading ? 'Memproses...' : 'Pulihkan Backup Terakhir',
              onPressed: _isLoading ? () {} : _handleRestoreLast,
            ),
            const SizedBox(height: 24),
            Text(
              'Backup dibuat di penyimpanan aplikasi. Restore dapat memilih '
              'file .json dari penyimpanan perangkat atau memakai backup '
              'terakhir yang dibuat aplikasi ini.',
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
