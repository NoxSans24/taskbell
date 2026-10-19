/// Konfigurasi alamat backend.
///
/// Nilai dapat dioverride saat build tanpa mengubah kode:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
