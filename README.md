# TaskBell

Aplikasi pengelola tugas bergaya pop-art untuk Android, dengan backend sinkronisasi
offline-first. Terdiri dari dua bagian:

| Bagian | Teknologi |
| --- | --- |
| `taskbell_app/` | Flutter 3.47, Riverpod, sqflite, flutter_local_notifications |
| `server/` | Node.js, Express, TypeScript, Prisma, PostgreSQL |

## Struktur

```
todolist/
├── server/                 # REST API + Prisma
│   ├── index.ts            # route auth & sync
│   ├── validators.ts       # skema Zod
│   ├── rate_limit.ts       # pembatas laju login/register
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── migrations/     # baseline migrasi
│   └── __tests__/          # Jest + Supertest
└── taskbell_app/           # aplikasi Flutter
    ├── lib/
    │   ├── core/           # tema, konfigurasi API
    │   ├── data/           # api client, repository, services, model
    │   ├── logic/          # provider Riverpod
    │   └── presentation/   # layar & widget
    └── test/               # unit & widget test
```

## Prasyarat

- Node.js 20+ dan npm
- PostgreSQL 14+
- Flutter 3.47+ dan Android SDK (untuk aplikasi mobile)

## Backend

```powershell
cd server
npm install
Copy-Item .env.example .env
```

Isi `.env`:

- `DATABASE_URL` — koneksi PostgreSQL.
- `JWT_SECRET` — **wajib** secret acak minimal 48 karakter. Server menolak
  nilai contoh dari `.env.example`. Buat dengan `openssl rand -base64 48`.
- `CORS_ORIGINS` — opsional, daftar origin web dipisah koma. Kosong berarti
  hanya `localhost`/`127.0.0.1`.
- `TRUST_PROXY` — set `1` bila di belakang reverse proxy.
- `TELEGRAM_TOKEN_KEY` — kunci AES-256-GCM 32 byte (base64) untuk mengenkripsi
  token bot Telegram. Buat dengan `openssl rand -base64 32`. Tanpa kunci ini
  endpoint Telegram mengembalikan 503 dan pengingat nonaktif.
- `REMINDERS_ENABLED` — set `0` untuk mematikan pengirim pengingat terjadwal.

### Database

Database baru:

```powershell
npm run db:deploy     # menerapkan prisma/migrations
npm run db:generate
```

Database lama yang sudah dibuat lewat `prisma db push`, tandai baseline sekali:

```powershell
npm run db:baseline   # prisma migrate resolve --applied 20261020000000_init
```

Perubahan skema berikutnya memakai `npm run db:migrate`, bukan `db push`.

### Menjalankan

```powershell
npm run dev      # ts-node-dev
npm run build    # kompilasi ke dist/
npm start        # menjalankan dist/
npm test         # Jest (butuh database pada DATABASE_URL)
```

Jika Jest gagal dengan `spawn EPERM` di lingkungan terbatas, jalankan
`npx jest --runInBand`.

### Endpoint

| Metode | Path | Keterangan |
| --- | --- | --- |
| GET | `/health` | status server |
| POST | `/auth/register` | registrasi + token |
| POST | `/auth/login` | login + token (2 jam) |
| GET | `/auth/me` | validasi sesi |
| POST | `/sync/push` | kirim antrean mutasi (maks 100) |
| GET | `/sync/pull` | tarik perubahan per cursor |
| GET | `/telegram/link` | status tautan Telegram |
| PUT | `/telegram/link` | simpan token bot + Chat ID (token dienkripsi) |
| DELETE | `/telegram/link` | putuskan tautan Telegram |
| POST | `/telegram/test` | kirim pesan uji ke chat tertaut |

## Aplikasi Flutter

```powershell
cd taskbell_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

- Emulator Android: `10.0.2.2` menunjuk ke host.
- Perangkat fisik: pakai IP LAN host, misalnya
  `--dart-define=API_BASE_URL=http://192.168.1.10:3000`.
- Produksi: gunakan HTTPS. Cleartext hanya diizinkan untuk
  `10.0.2.2`, `localhost`, dan `127.0.0.1` (lihat
  `android/app/src/main/res/xml/network_security_config.xml`).

### Pemeriksaan

```powershell
flutter analyze
flutter test
```

## Build release Android

Signing dikonfigurasi lewat `android/keystore.properties` (tidak masuk Git):

```properties
storeFile=C:/path/keystore-release.jks
storePassword=...
keyAlias=...
keyPassword=...
```

Tanpa file tersebut, build release memakai debug key dan **tidak boleh
didistribusikan**.

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.contoh.id
```

## CI

Workflow GitHub Actions tersedia di `.github/workflows/`:

| Workflow | Isi |
| --- | --- |
| `server-ci.yml` | PostgreSQL 16 service, `npm ci`, Prisma generate + migrate deploy, `tsc --noEmit`, Jest, `npm audit --omit=dev` |
| `flutter-ci.yml` | `flutter pub get`, `flutter analyze`, `flutter test`, build APK release, unggah artefak |

Rahasia CI (`JWT_SECRET`, `TELEGRAM_TOKEN_KEY`) dibuat acak saat workflow
berjalan; tidak ada kredensial yang disimpan di repository. Build APK di CI
memakai debug signing karena keystore tidak tersedia, sehingga artefaknya hanya
untuk verifikasi, bukan distribusi. Workflow aktif setelah repository di-push
ke GitHub.

## Keamanan

- Jangan commit `.env`, keystore, atau `keystore.properties`.
- Token disimpan di `flutter_secure_storage`, bukan SharedPreferences.
- Login dibatasi 10 percobaan/15 menit per IP+email; registrasi 20/jam per IP.
- Password di-hash dengan bcrypt (via `bcryptjs`, cost 12); hash lama dari
  `bcrypt` native tetap dapat diverifikasi.
- Token bot Telegram disimpan terenkripsi (AES-256-GCM) di server, tidak pernah
  dikembalikan ke klien, dan tidak disimpan di perangkat.
- Database lokal dienkripsi SQLCipher. Kunci 32 byte dibuat acak dan disimpan di
  `flutter_secure_storage`, bukan di source code. Database plaintext dari versi
  lama dimigrasikan otomatis saat pertama dibuka.
- `android:allowBackup="false"` mencegah database terenkripsi dipulihkan tanpa
  kunci aslinya.
- Setiap endpoint sinkronisasi memfilter data berdasarkan `userId` dari token.

## Batasan yang diketahui

- Kalender menyediakan tampilan bulanan dasar; belum ada tampilan mingguan
  atau agenda berulang.
- Pengingat Telegram dikirim server setiap menit untuk tugas yang **sudah
  tersinkron** dan tenggatnya tiba. Tugas yang belum pernah disinkronkan tetap
  mendapat notifikasi lokal, bukan Telegram.
- Data lokal dienkripsi SQLCipher per akun. **File backup JSON tidak
  dienkripsi**, jadi perlakukan file backup seperti data sensitif.
- Menghapus data aplikasi atau kehilangan secure storage membuat database lokal
  tidak dapat dibuka; gunakan backup JSON secara berkala.
- Rate limiter berbasis memori, perlu Redis untuk deployment multi-instance.
