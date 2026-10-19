import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/services/backup_service.dart';
import 'package:taskbell_app/data/services/backup_validator.dart';
import 'package:taskbell_app/logic/providers/auth_provider.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';
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

    final password = await _promptPassword(
      title: 'Enkripsi Backup',
      description:
          'Kosongkan untuk backup tanpa kata sandi. Backup terenkripsi '
          'meminta kata sandi ini saat dipulihkan.',
      allowEmpty: true,
    );

    if (password == null) return;

    setState(() => _isLoading = true);

    try {
      final service = BackupService(userId);
      final path = await service.exportBackup(password: password);
      final backup = await service.readBackup(
        path,
        password: password.isEmpty ? null : password,
      );

      if (!mounted) return;
      _showMessage(
        'Backup tersimpan: ${path.split('/').last} '
        '(${backup.taskCount} tugas, ${backup.categoryCount} kategori'
        '${password.isEmpty ? '' : ', terenkripsi'}).',
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

    try {
      final service = BackupService(userId);
      final path = await service.backupPath();
      final credentials = await _passwordForRestore(service, path);
      if (credentials.cancelled) return;

      setState(() => _isLoading = true);
      await _restoreFromPath(service, path, userId, credentials.password);
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
      final credentials = await _passwordForRestore(service, file.path);
      if (credentials.cancelled) return;

      setState(() => _isLoading = true);
      await _restoreFromPath(service, file.path, userId, credentials.password);
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

  Future<({String? password, bool cancelled})> _passwordForRestore(
    BackupService service,
    String path,
  ) async {
    final encrypted = await service.isEncrypted(path);

    if (!encrypted) {
      return (password: null, cancelled: false);
    }

    final password = await _promptPassword(
      title: 'Kata Sandi Backup',
      description: 'File backup ini terenkripsi. Masukkan kata sandinya.',
      allowEmpty: false,
    );

    return (password: password, cancelled: password == null);
  }

  Future<void> _restoreFromPath(
    BackupService service,
    String path,
    String userId,
    String? password,
  ) async {
    final backup = await service.readBackup(path, password: password);

    if (!mounted) return;

    final confirmed = await _confirmRestore(backup);
    if (confirmed != true) return;

    await service.importBackup(path, password: password);

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

  Future<String?> _promptPassword({
    required String title,
    required String description,
    required bool allowEmpty,
  }) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _BackupPasswordDialog(
        title: title,
        description: description,
        allowEmpty: allowEmpty,
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
              'terakhir. Backup dapat dilindungi kata sandi (AES-256-GCM).',
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({
    required this.title,
    required this.description,
    required this.allowEmpty,
  });

  final String title;
  final String description;
  final bool allowEmpty;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;

    if (!widget.allowEmpty && value.isEmpty) {
      setState(() => _error = 'Kata sandi wajib diisi');
      return;
    }

    if (value.isNotEmpty && value.length < 8) {
      setState(() => _error = 'Minimal 8 karakter');
      return;
    }

    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            maxLength: 128,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Kata sandi backup',
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: _obscure
                    ? 'Tampilkan kata sandi'
                    : 'Sembunyikan kata sandi',
                icon: AppIcon(_obscure ? AppIcons.eye : AppIcons.eyeOff),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Lanjut'),
        ),
      ],
    );
  }
}
