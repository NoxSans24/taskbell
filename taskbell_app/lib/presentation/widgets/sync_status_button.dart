import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/logic/providers/sync_provider.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';

class SyncStatusButton extends ConsumerWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final sync = ref.watch(syncControllerProvider);
    final isSyncing = sync.phase == SyncPhase.syncing;

    final icon = switch (sync.phase) {
      SyncPhase.idle => AppIcons.cloud,
      SyncPhase.syncing => AppIcons.refresh,
      SyncPhase.success => AppIcons.cloudCheck,
      SyncPhase.error => AppIcons.cloudOff,
      SyncPhase.unauthenticated => AppIcons.lock,
    };

    return IconButton(
      tooltip: _tooltip(sync),
      onPressed: isSyncing ? null : () => _run(context, ref),
      icon: isSyncing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : AppIcon(
              icon,
              color:
                  sync.phase == SyncPhase.error ? palette.error : palette.ink,
            ),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    await ref.read(syncControllerProvider.notifier).syncNow();

    if (!context.mounted) return;

    final sync = ref.read(syncControllerProvider);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    if (sync.phase == SyncPhase.success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sinkronisasi selesai.')),
      );
    } else if (sync.phase == SyncPhase.error) {
      messenger.showSnackBar(
        SnackBar(content: Text(sync.message ?? 'Sinkronisasi gagal.')),
      );
    }
  }

  String _tooltip(SyncState sync) {
    return switch (sync.phase) {
      SyncPhase.idle => 'Sinkronkan sekarang',
      SyncPhase.syncing => 'Menyinkronkan...',
      SyncPhase.success => 'Tersinkron',
      SyncPhase.error => sync.message ?? 'Sinkronisasi gagal',
      SyncPhase.unauthenticated => 'Masuk untuk menyinkronkan',
    };
  }
}
