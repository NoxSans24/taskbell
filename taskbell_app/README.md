# TaskBell — Aplikasi Flutter

Dokumentasi lengkap (instalasi, konfigurasi backend, pengujian, build release)
ada di [README utama](../README.md).

Ringkas:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
flutter analyze
flutter test
```

## Font

- `assets/fonts/PlusJakartaSans.ttf` — SIL Open Font License,
  lihat `assets/fonts/OFL-PlusJakartaSans.txt`.
- `assets/fonts/DMSans.ttf` — SIL Open Font License,
  lihat `assets/fonts/OFL-DMSans.txt`.

Keduanya variable font; bobot diatur melalui `fontVariations` di `AppTheme`
dan beberapa judul layar.

## Ikon

Ikon UI memakai set [Lucide](https://lucide.dev) (lisensi ISC) di
`assets/icons/svg/`. Lisensi lengkap ada di
`assets/icons/svg/LICENSE-lucide.txt`. Ikon dirender lewat `AppIcon`
(`lib/presentation/widgets/app_icon.dart`) dan otomatis mengikuti warna tema.

## Database lokal

Database per akun dienkripsi dengan SQLCipher (`sqflite_sqlcipher`). Kunci acak
32 byte disimpan di `flutter_secure_storage`. Database plaintext dari versi
sebelumnya dimigrasikan otomatis (file lama disimpan sebagai `.legacy` selama
proses dan dihapus setelah berhasil).
