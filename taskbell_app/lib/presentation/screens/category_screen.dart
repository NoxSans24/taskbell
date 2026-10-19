import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/models/category_model.dart';
import 'package:taskbell_app/logic/providers/category_provider.dart';
import 'package:taskbell_app/logic/providers/sync_provider.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';
import 'package:taskbell_app/presentation/widgets/comic_components.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  bool _isBusy = false;

  Future<void> _addCategory() async {
    final name = await _promptName(title: 'Kategori Baru');
    if (name == null) return;

    await _run(
      () => ref.read(categoryListProvider.notifier).add(name),
      'Kategori ditambahkan.',
    );
  }

  Future<void> _renameCategory(CategoryModel category) async {
    final name = await _promptName(
      title: 'Ubah Nama Kategori',
      initial: category.name,
    );
    if (name == null || name == category.name) return;

    await _run(
      () => ref.read(categoryListProvider.notifier).rename(category.id, name),
      'Kategori diperbarui.',
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    setState(() => _isBusy = true);
    final count =
        await ref.read(categoryListProvider.notifier).taskCount(category.name);
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (count > 0) {
      _showMessage(
        'Tidak bisa menghapus "${category.name}": masih dipakai $count tugas.',
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('Kategori "${category.name}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _run(
      () => ref.read(categoryListProvider.notifier).remove(category.id),
      'Kategori dihapus.',
    );
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _isBusy = true);

    try {
      await action();
      await ref.read(syncControllerProvider.notifier).syncNow();
      if (!mounted) return;
      _showMessage(success);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Gagal menyimpan kategori. Nama mungkin sudah dipakai.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<String?> _promptName({
    required String title,
    String? initial,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _CategoryNameDialog(title: title, initial: initial),
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
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kategori',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah kategori',
            onPressed: _isBusy ? null : _addCategory,
            icon: const AppIcon(AppIcons.plus),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Belum ada kategori. Tambahkan satu untuk mengelompokkan tugas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];

              return ComicCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ubah nama',
                      onPressed:
                          _isBusy ? null : () => _renameCategory(category),
                      icon: AppIcon(AppIcons.pencil, color: palette.ink),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed:
                          _isBusy ? null : () => _deleteCategory(category),
                      icon: AppIcon(AppIcons.trash, color: palette.error),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Gagal memuat kategori.'),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.read(categoryListProvider.notifier).refresh(),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog dimiliki widget tersendiri agar controller ter-dispose setelah
/// animasi penutupan selesai, bukan saat dialog masih dirender.
class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();

    if (trimmed.isEmpty) {
      setState(() => _error = 'Nama wajib diisi');
      return;
    }

    Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Nama kategori',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
