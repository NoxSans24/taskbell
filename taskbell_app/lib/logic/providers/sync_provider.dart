import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/data/api/api_client.dart';
import 'package:taskbell_app/data/services/sync_service.dart';
import 'package:taskbell_app/logic/providers/auth_provider.dart';
import 'package:taskbell_app/logic/providers/category_provider.dart';
import 'package:taskbell_app/logic/providers/task_provider.dart';

enum SyncPhase { idle, syncing, success, error, unauthenticated }

class SyncState {
  final SyncPhase phase;
  final String? message;
  final DateTime? lastSyncedAt;

  const SyncState({
    this.phase = SyncPhase.idle,
    this.message,
    this.lastSyncedAt,
  });

  SyncState copyWith({
    SyncPhase? phase,
    String? message,
    bool clearMessage = false,
    DateTime? lastSyncedAt,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(ref);
});

/// Menjalankan push lalu pull. Dipakai setelah login, saat aplikasi dibuka
/// kembali, dan setelah perubahan data lokal.
class SyncController extends StateNotifier<SyncState> {
  final Ref _ref;
  bool _isRunning = false;

  SyncController(this._ref) : super(const SyncState());

  Future<void> syncNow() async {
    if (_isRunning) return;

    final userId = _ref.read(authUserIdProvider);
    if (userId == null) {
      state = const SyncState(phase: SyncPhase.unauthenticated);
      return;
    }

    _isRunning = true;
    state = state.copyWith(phase: SyncPhase.syncing, clearMessage: true);

    try {
      // Batas waktu mencegah status "menyinkronkan" menggantung selamanya
      // bila penyimpanan lokal tidak merespons.
      final db = await _ref
          .read(databaseProvider(userId).future)
          .timeout(const Duration(seconds: 30));
      final api = _ref.read(apiClientProvider);
      final service = SyncService(db, api);

      await service.pushMutations();
      await service.pullChanges();

      if (!mounted) return;
      state = SyncState(phase: SyncPhase.success, lastSyncedAt: DateTime.now());
      _ref.invalidate(taskListProvider);
      _ref.invalidate(categoryListProvider);
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.isUnauthorized) {
        await _ref
            .read(authControllerProvider.notifier)
            .logout(sessionExpired: true);
        state = const SyncState(
          phase: SyncPhase.unauthenticated,
          message: 'Sesi berakhir. Silakan masuk kembali.',
        );
      } else {
        state = SyncState(
          phase: SyncPhase.error,
          message: error.message,
          lastSyncedAt: state.lastSyncedAt,
        );
      }
    } catch (_) {
      if (!mounted) return;
      state = SyncState(
        phase: SyncPhase.error,
        message: 'Sinkronisasi gagal. Data tetap tersimpan di perangkat.',
        lastSyncedAt: state.lastSyncedAt,
      );
    } finally {
      _isRunning = false;
    }
  }
}
