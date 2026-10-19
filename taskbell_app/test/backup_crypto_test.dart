import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskbell_app/data/services/backup_crypto.dart';
import 'package:taskbell_app/data/services/backup_validator.dart';

const String _payload =
    '{"format_version":1,"tasks":[],"categories":[],"exported_at":"2026-10-20T00:00:00Z"}';

void main() {
  group('Backup encryption', () {
    test('round trips with the correct password', () async {
      final encrypted = await encryptBackup(
        plainJson: _payload,
        password: 'Password123!',
      );

      expect(encrypted, isNot(contains('exported_at')));
      expect(tryParseEncryptedEnvelope(encrypted), isNotNull);

      final decrypted = await decryptBackup(
        raw: encrypted,
        password: 'Password123!',
      );

      expect(decrypted, _payload);
    });

    test('rejects the wrong password', () async {
      final encrypted = await encryptBackup(
        plainJson: _payload,
        password: 'Password123!',
      );

      await expectLater(
        decryptBackup(raw: encrypted, password: 'SalahSekali!'),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('rejects tampered ciphertext', () async {
      final encrypted = await encryptBackup(
        plainJson: _payload,
        password: 'Password123!',
      );
      final envelope = jsonDecode(encrypted) as Map<String, dynamic>;
      final cipher = envelope['cipher'] as Map<String, dynamic>;
      final bytes = base64Decode(cipher['ciphertext'] as String);
      bytes[0] = bytes[0] ^ 0x01;
      cipher['ciphertext'] = base64Encode(bytes);

      await expectLater(
        decryptBackup(raw: jsonEncode(envelope), password: 'Password123!'),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('plaintext backup is not detected as encrypted', () {
      expect(tryParseEncryptedEnvelope(_payload), isNull);
    });

    test('rejects an incomplete envelope', () {
      expect(
        () => parseEncryptedEnvelope(
          '{"format_version":2,"encrypted":true}',
        ),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('rejects an unsupported KDF iteration count', () {
      final envelope = {
        'format_version': 2,
        'encrypted': true,
        'kdf': {
          'iterations': 1,
          'salt': base64Encode(List<int>.filled(16, 1)),
        },
        'cipher': {
          'nonce': base64Encode(List<int>.filled(12, 1)),
          'mac': base64Encode(List<int>.filled(16, 1)),
          'ciphertext': base64Encode([1, 2, 3]),
        },
      };

      expect(
        () => parseEncryptedEnvelope(jsonEncode(envelope)),
        throwsA(isA<BackupValidationException>()),
      );
    });
  });
}
