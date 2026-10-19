import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:taskbell_app/data/models/auth_session.dart';

/// Kegagalan yang layak ditampilkan ke pengguna.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class ApiClient {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _emailKey = 'auth_user_email';
  static const Duration _timeout = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _http;
  final FlutterSecureStorage _storage;

  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  })  : _http = httpClient ?? http.Client(),
        _storage = storage;

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<AuthSession?> readStoredSession() async {
    final token = await _storage.read(key: _tokenKey);
    final userId = await _storage.read(key: _userIdKey);
    final email = await _storage.read(key: _emailKey);

    if (token == null || userId == null || email == null) return null;

    return AuthSession(token: token, userId: userId, email: email);
  }

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _userIdKey, value: session.userId);
    await _storage.write(key: _emailKey, value: session.email);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _emailKey);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _authenticate(
      '/auth/login',
      email: email,
      password: password,
      expectedStatus: 200,
    );
  }

  Future<AuthSession> register({
    required String email,
    required String password,
  }) {
    return _authenticate(
      '/auth/register',
      email: email,
      password: password,
      expectedStatus: 201,
    );
  }

  Future<AuthSession> _authenticate(
    String path, {
    required String email,
    required String password,
    required int expectedStatus,
  }) async {
    final response = await _send(
      'POST',
      path,
      body: {'email': email, 'password': password},
    );

    if (response.statusCode != expectedStatus) {
      throw _exceptionFor(response);
    }

    final data = _decodeObject(response);
    final user = data['user'];
    final token = data['token'];

    if (user is! Map<String, dynamic> || token is! String) {
      throw const ApiException('Respons autentikasi tidak dikenali.');
    }

    final session = AuthSession(
      token: token,
      userId: user['id'] as String,
      email: user['email'] as String,
    );

    await saveSession(session);
    return session;
  }

  /// Memvalidasi token tersimpan ke server.
  Future<AuthSession> fetchProfile(AuthSession stored) async {
    final response = await _send('GET', '/auth/me');

    if (response.statusCode == 401) {
      await clearSession();
      throw const ApiException('Sesi berakhir. Silakan masuk kembali.',
          statusCode: 401);
    }

    if (response.statusCode != 200) {
      throw _exceptionFor(response);
    }

    final data = _decodeObject(response);
    final user = data['user'];

    if (user is! Map<String, dynamic>) {
      throw const ApiException('Respons profil tidak dikenali.');
    }

    final refreshed = AuthSession(
      token: stored.token,
      userId: user['id'] as String,
      email: user['email'] as String,
    );

    await saveSession(refreshed);
    return refreshed;
  }

  Future<List<dynamic>> pushMutations(
      List<Map<String, dynamic>> mutations) async {
    final response = await _send('POST', '/sync/push', body: mutations);

    if (response.statusCode != 200) {
      throw _exceptionFor(response);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const ApiException('Respons sinkronisasi tidak valid.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> pullChanges(String cursor, int limit) async {
    final uri = Uri.parse('$baseUrl/sync/pull').replace(
      queryParameters: {'cursor': cursor, 'limit': '$limit'},
    );
    final response = await _sendUri('GET', uri);

    if (response.statusCode != 200) {
      throw _exceptionFor(response);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons sinkronisasi tidak valid.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> fetchTelegramLink() async {
    final response = await _send('GET', '/telegram/link');

    if (response.statusCode != 200) {
      throw _exceptionFor(response);
    }

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> saveTelegramLink({
    required String botToken,
    required String chatId,
  }) async {
    final response = await _send(
      'PUT',
      '/telegram/link',
      body: {'botToken': botToken, 'chatId': chatId},
    );

    if (response.statusCode != 200) {
      throw _exceptionFor(response);
    }

    return _decodeObject(response);
  }

  Future<void> deleteTelegramLink() async {
    final response = await _send('DELETE', '/telegram/link');

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw _exceptionFor(response);
    }
  }

  Future<void> sendTelegramTest() async {
    final response = await _send('POST', '/telegram/test', body: const {});

    if (response.statusCode != 200) {
      throw _exceptionFor(response);
    }
  }

  Future<http.Response> _send(String method, String path, {Object? body}) {
    return _sendUri(method, Uri.parse('$baseUrl$path'), body: body);
  }

  Future<http.Response> _sendUri(String method, Uri uri, {Object? body}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    try {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Penyimpanan aman tidak tersedia (misalnya di lingkungan uji):
      // lanjutkan tanpa token agar server yang menolak dengan 401.
    }

    try {
      final request = switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          ),
        'PUT' => _http.put(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          ),
        'DELETE' => _http.delete(uri, headers: headers),
        _ => throw UnsupportedError('Metode $method tidak didukung'),
      };

      return await request.timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('Server tidak merespons. Periksa koneksi Anda.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Tidak dapat menghubungi server. Periksa koneksi Anda.',
      );
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons server tidak valid.');
    }
    return decoded;
  }

  ApiException _exceptionFor(http.Response response) {
    String message;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        message = decoded['error'] as String;
      } else {
        message = _defaultMessage(response.statusCode);
      }
    } catch (_) {
      message = _defaultMessage(response.statusCode);
    }

    return ApiException(message, statusCode: response.statusCode);
  }

  String _defaultMessage(int status) {
    return switch (status) {
      400 => 'Data yang dikirim tidak valid.',
      401 => 'Sesi berakhir. Silakan masuk kembali.',
      409 => 'Email sudah terdaftar.',
      413 => 'Data yang dikirim terlalu besar.',
      >= 500 => 'Server sedang bermasalah. Coba lagi nanti.',
      _ => 'Permintaan gagal (kode $status).',
    };
  }
}
