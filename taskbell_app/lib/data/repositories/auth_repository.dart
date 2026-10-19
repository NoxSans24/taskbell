import 'package:taskbell_app/data/api/api_client.dart';
import 'package:taskbell_app/data/models/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession> register({
    required String email,
    required String password,
  });

  Future<void> logout();
}

class ApiAuthRepository implements AuthRepository {
  final ApiClient _api;

  ApiAuthRepository(this._api);

  @override
  Future<AuthSession?> restoreSession() async {
    final stored = await _api.readStoredSession();
    if (stored == null) return null;

    try {
      return await _api.fetchProfile(stored);
    } on ApiException catch (error) {
      if (error.isUnauthorized) return null;

      // Sedang offline: sesi lokal tetap dipakai agar aplikasi dapat dibuka.
      return stored;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _api.login(email: email, password: password);
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) {
    return _api.register(email: email, password: password);
  }

  @override
  Future<void> logout() => _api.clearSession();
}
