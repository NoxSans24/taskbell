# Laporan Audit & Status — TaskBell

**Tanggal:** 20 Oktober 2026
**Cakupan:** `server/` (Express + Prisma + PostgreSQL) dan `taskbell_app/` (Flutter Android)
**Status dokumen:** menggantikan laporan 17 Oktober 2026 yang klaimnya tidak sesuai
implementasi saat itu.

> Catatan: laporan lama menyatakan "BERHASIL DIVERIFIKASI 100%" dengan log
> pengujian yang tidak cocok dengan kode (misalnya jumlah test dan nama test).
> Dokumen ini hanya memuat hasil yang benar-benar dijalankan ulang.

## Ringkasan status

| Area | Status | Bukti |
| --- | --- | --- |
| Autentikasi (API + UI) | Berfungsi | register/login/me, token di secure storage, gate login |
| CRUD tugas | Berfungsi | tambah, edit, hapus, tandai selesai |
| Kategori | Berfungsi | CRUD di UI, hapus ditolak bila masih dipakai |
| Sinkronisasi | Berfungsi | push/pull otomatis, idempoten, sequence atomik |
| Isolasi data | Berfungsi | uji lintas pengguna: pull 0, mutasi asing ditolak |
| Pengingat lokal | Berfungsi | flutter_local_notifications |
| Pengingat Telegram | Berfungsi | scheduler server, token terenkripsi AES-256-GCM |
| Backup/restore | Berfungsi | validasi ketat, pratinjau, pemilih file, transaksi |
| Database lokal | Terenkripsi | SQLCipher, kunci di secure storage, migrasi otomatis |
| Tema terang/gelap | Berfungsi | palet semantik + persistensi |
| Kalender | Berfungsi (dasar) | tampilan bulanan, penanda tugas, daftar per hari |
| Aksesibilitas | Berfungsi (dasar) | target 48 dp, semantik, skala 200%, kontras AA |
| Ikon | Berfungsi | 25 ikon SVG Lucide (ISC), bukan Material Icons |
| Migrasi database | Berfungsi | 2 migrasi Prisma + `db:deploy` |
| Release APK | Berfungsi | signing release, `com.taskbell.app` |

## Hasil pengujian aktual

| Pemeriksaan | Hasil |
| --- | --- |
| `npx tsc --noEmit` | Exit 0 |
| `npx jest --runInBand` | 34/34 lulus (3 suite) |
| `npm audit --omit=dev` | 0 kerentanan |
| `flutter analyze` | No issues found |
| `flutter test` | 24/24 lulus |
| `flutter build apk --release` | Berhasil (54 MB) |
| Uji isolasi lintas pengguna | Lulus |
| Uji paralel 20 push | 20 sukses, sequence unik |
| Token palsu dengan secret contoh | Ditolak 401 |

## Risiko dan batasan yang masih ada

1. **Kalender** baru tingkat dasar (bulanan); belum ada tampilan mingguan,
   agenda berulang, atau integrasi kalender pihak ketiga.
2. **Backup** hanya membaca format `format_version: 1`; file dari versi lain
   ditolak dengan pesan yang jelas.
3. **Backup JSON** dapat dienkripsi dengan kata sandi (AES-256-GCM), tetapi
   backup tanpa kata sandi tetap berisi data terbaca.
4. **Scheduler pengingat** memakai klaim atomik (unique constraint) sehingga
   aman untuk beberapa instance; klaim yang tertinggal dipulihkan setelah
   10 menit.
5. **`npm audit` penuh** (termasuk devDependencies) masih melaporkan isu dari
   toolchain Jest; tidak ikut ke produksi.
6. **Font** dibundel sebagai variable font OFL; bobot diatur lewat
   `fontVariations`.

## Cara menjalankan ulang pemeriksaan

```powershell
# Backend
cd server
npx tsc --noEmit
npx jest --runInBand
npm audit --omit=dev

# Aplikasi
cd ..\taskbell_app
flutter analyze
flutter test
flutter build apk --release
```
