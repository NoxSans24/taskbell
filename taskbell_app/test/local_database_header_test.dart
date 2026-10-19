import 'package:flutter_test/flutter_test.dart';
import 'package:taskbell_app/data/services/local_database.dart';

void main() {
  group('Deteksi database plaintext', () {
    test('mengenali header SQLite standar', () {
      final header = 'SQLite format 3\u0000'.codeUnits;

      expect(isPlaintextSqliteHeader(header), isTrue);
      expect(isPlaintextSqliteHeader([...header, 0, 0]), isTrue);
    });

    test('menolak header terenkripsi atau rusak', () {
      expect(
        isPlaintextSqliteHeader(
          List<int>.generate(16, (index) => index + 1),
        ),
        isFalse,
      );
      expect(isPlaintextSqliteHeader(const []), isFalse);
      expect(isPlaintextSqliteHeader('SQLite'.codeUnits), isFalse);
    });
  });
}
