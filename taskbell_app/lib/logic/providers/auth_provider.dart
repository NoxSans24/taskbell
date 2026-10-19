import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:taskbell_app/core/config/api_config.dart';
import 'package:taskbell_app/data/api/api_client.dart';
import 'package:taskbell_app/data/repositories/auth_repository.dart';
import 'package:taskbell_app/data/repositories/task_repository.dart';
import 'package:taskbell_app/data/services/local_database.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final bool sessionExpired;

  const AuthState({
    required this.status,
    this.userId,
    this.email,
    this.sessionExpired = false,
  });

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.unauthenticated({bool sessionExpired = false})
      : this(
            status: AuthStatus.unauthenticated, sessionExpired: sessionExpired);

  const AuthState.authenticated({
    required String userId,
    required String email,
  }) : this(
          status: AuthStatus.authenticated,
          userId: userId,
          email: email,
        );
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: ApiConfig.baseUrl);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(apiClientProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});

/// Identitas pengguna aktif. `null` berarti belum masuk.
final authUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).userId;
});

final databaseProvider =
    FutureProvider.family<Database, String>((ref, userId) async {
  return LocalDatabase.instance.getDatabaseForUser(userId);
});

final taskRepositoryProvider = Provider<TaskRepository?>((ref) {
  final userId = ref.watch(authUserIdProvider);

  if (userId == null || userId.isEmpty) {
    return null;
  }

  final dbAsync = ref.watch(databaseProvider(userId));

  return dbAsync.maybeWhen(
    data: (db) => TaskRepository(db),
    orElse: () => null,
  );
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref)
      : super(const AuthState.loading()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final session = await _repository.restoreSession();
      if (!mounted) return;

      state = session == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(
              userId: session.userId,
              email: session.email,
            );
    } catch (_) {
      if (!mounted) return;
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    final session = await _repository.login(email: email, password: password);
    state = AuthState.authenticated(
      userId: session.userId,
      email: session.email,
    );
  }

  Future<void> register(String email, String password) async {
    final session =
        await _repository.register(email: email, password: password);
    state = AuthState.authenticated(
      userId: session.userId,
      email: session.email,
    );
  }

  Future<void> logout({bool sessionExpired = false}) async {
    final previousUserId = state.userId;

    try {
      await _repository.logout();
    } catch (_) {
      // Sesi lokal tetap dibersihkan meskipun penyimpanan gagal.
    }

    state = AuthState.unauthenticated(sessionExpired: sessionExpired);

    if (previousUserId != null) {
      await LocalDatabase.instance.closeDatabaseForUser(previousUserId);
      // Buang koneksi yang sudah ditutup agar login berikutnya membuka ulang.
      _ref.invalidate(databaseProvider(previousUserId));
    }
  }
}
