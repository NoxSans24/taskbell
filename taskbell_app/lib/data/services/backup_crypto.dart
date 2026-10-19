import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:taskbell_app/data/services/backup_validator.dart';

const int encryptedBackupVersion = 2;
const int _kdfIterations = 120000;
const int _saltBytes = 16;
const int _nonceBytes = 12;

class EncryptedBackupEnvelope {
  final int iterations;
  final List<int> salt;
  final List<int> nonce;
  final List<int> mac;
  final List<int> cipherText;

  const EncryptedBackupEnvelope({
    required this.iterations,
    required this.salt,
    required this.nonce,
    required this.mac,
    required this.cipherText,
  });
}

/// Mengenkripsi payload JSON dengan kata sandi pengguna.
///
/// Kunci diturunkan dengan PBKDF2-HMAC-SHA256 dan data dienkripsi dengan
/// AES-256-GCM. Salt dan nonce dibuat acak untuk setiap backup.
Future<String> encryptBackup({
  required String plainJson,
  required String password,
}) async {
  final random = Random.secure();
  final salt = List<int>.generate(_saltBytes, (_) => random.nextInt(256));
  final nonce = List<int>.generate(_nonceBytes, (_) => random.nextInt(256));

  final key = await _deriveKey(password, salt, _kdfIterations);
  final box = await AesGcm.with256bits().encrypt(
    utf8.encode(plainJson),
    secretKey: key,
    nonce: nonce,
  );

  return jsonEncode({
    'format_version': encryptedBackupVersion,
    'encrypted': true,
    'kdf': {
      'algorithm': 'PBKDF2-HMAC-SHA256',
      'iterations': _kdfIterations,
      'salt': base64Encode(salt),
    },
    'cipher': {
      'algorithm': 'AES-256-GCM',
      'nonce': base64Encode(nonce),
      'mac': base64Encode(box.mac.bytes),
      'ciphertext': base64Encode(box.cipherText),
    },
  });
}

Future<String> decryptBackup({
  required String raw,
  required String password,
}) async {
  final envelope = parseEncryptedEnvelope(raw);
  final key = await _deriveKey(password, envelope.salt, envelope.iterations);

  try {
    final clear = await AesGcm.with256bits().decrypt(
      SecretBox(
        envelope.cipherText,
        nonce: envelope.nonce,
        mac: Mac(envelope.mac),
      ),
      secretKey: key,
    );

    return utf8.decode(clear);
  } on SecretBoxAuthenticationError {
    throw const BackupValidationException(
      'Kata sandi salah atau file backup rusak.',
    );
  } on FormatException {
    throw const BackupValidationException(
      'Isi backup tidak dapat dibaca.',
    );
  }
}

/// Mengembalikan envelope bila file adalah backup terenkripsi, atau null bila
/// file adalah backup lama (plaintext).
EncryptedBackupEnvelope? tryParseEncryptedEnvelope(String raw) {
  dynamic decoded;

  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, dynamic>) return null;

  final isEncrypted = decoded['format_version'] == encryptedBackupVersion ||
      decoded['encrypted'] == true;

  if (!isEncrypted) return null;

  return parseEncryptedEnvelope(raw);
}

EncryptedBackupEnvelope parseEncryptedEnvelope(String raw) {
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

  if (decoded['format_version'] != encryptedBackupVersion ||
      decoded['encrypted'] != true) {
    throw const BackupValidationException(
      'Format backup terenkripsi tidak dikenali.',
    );
  }

  final kdf = decoded['kdf'];
  final cipher = decoded['cipher'];

  if (kdf is! Map<String, dynamic> || cipher is! Map<String, dynamic>) {
    throw const BackupValidationException('Metadata enkripsi tidak lengkap.');
  }

  final iterations = kdf['iterations'];
  if (iterations is! int || iterations < 10000 || iterations > 1000000) {
    throw const BackupValidationException(
      'Parameter KDF pada backup tidak valid.',
    );
  }

  return EncryptedBackupEnvelope(
    iterations: iterations,
    salt: _decodeBase64(kdf['salt'], 'salt', minLength: 8, maxLength: 32),
    nonce:
        _decodeBase64(cipher['nonce'], 'nonce', minLength: 12, maxLength: 16),
    mac: _decodeBase64(cipher['mac'], 'mac', minLength: 16, maxLength: 32),
    cipherText: _decodeBase64(
      cipher['ciphertext'],
      'ciphertext',
      minLength: 1,
    ),
  );
}

List<int> _decodeBase64(
  dynamic value,
  String label, {
  required int minLength,
  int? maxLength,
}) {
  if (value is! String || value.isEmpty) {
    throw BackupValidationException('Field $label tidak ditemukan.');
  }

  late final List<int> bytes;

  try {
    bytes = base64Decode(value);
  } on FormatException {
    throw BackupValidationException('Field $label bukan base64 yang valid.');
  }

  if (bytes.length < minLength ||
      (maxLength != null && bytes.length > maxLength)) {
    throw BackupValidationException('Panjang field $label tidak valid.');
  }

  return bytes;
}

Future<SecretKey> _deriveKey(
  String password,
  List<int> salt,
  int iterations,
) {
  return Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: password, nonce: salt);
}
