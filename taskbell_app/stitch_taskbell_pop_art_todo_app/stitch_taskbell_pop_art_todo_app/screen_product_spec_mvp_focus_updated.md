# Screen & Product Specification --- TaskBell Android (MVP Focus)

## 1. Ringkasan Produk

TaskBell adalah aplikasi To-do List Android dengan integrasi pengingat satu arah via Telegram bot, dibangun dengan arsitektur teknologi final:
- **Frontend**: Flutter / Dart (Android-first, mobile UX, safe area & keyboard-adaptive)
- **Backend**: Node.js + Prisma ORM + PostgreSQL (database `taskbell`)

### Target Audiens
Pelajar, mahasiswa, dan individu yang membutuhkan manajemen tugas harian yang fokus, visual, dan andal dengan notifikasi langsung ke Telegram.

### Aturan Ikon & UI (Strict SVG-Only — Standar Mutlak)
- **100% SVG Inline / Lokal**: Tidak ada emoji, karakter Unicode sebagai ikon, icon font, atau bitmap raster (PNG/JPG) untuk kontrol UI.
- Semua tombol aksi ber-SVG memiliki label aksesibilitas (`semanticsLabel` di Flutter / `aria-label`).
- Semua status penting disajikan dengan kombinasi ikon SVG dan teks eksplisit (tidak mengandalkan warna semata).

---

## 2. Cakupan Fitur (Scoping)

### Scope MVP (Rilis Pertama)
1. **Autentikasi Pengguna**: Registrasi akun baru, Masuk (Login), dan Keluar (Logout) dengan sesi terisolasi per akun.
2. **Manajemen Tugas (CRUD Tunggal)**:
   - Buat tugas baru, lihat daftar & detail, edit, tandai selesai, dan hapus tugas.
   - Field tugas MVP: Judul (wajib), Deskripsi/Catatan (opsional), Kategori (Kuliah, Kerja, Pribadi, dll.), Prioritas (Rendah, Sedang, Tinggi), Tenggat Waktu (Tanggal & Jam opsional).
3. **Pencarian, Filter & Sorting**:
   - Filter cepat: Semua, Hari Ini, Mendatang, Terlambat, Selesai.
   - Filter kategori dan urutan tenggat waktu.
4. **Kalender & Agenda Dasar**:
   - Navigasi bulan dinamis (sebelumnya/berikutnya), penanda tanggal terpilih, dan tampilan agenda vertikal harian dengan state isi dan agenda kosong (*empty state*).
5. **Integrasi Telegram Dasar (Satu Arah)**:
   - Verifikasi sambungan bot Telegram dengan alur kode linking / One-Time Verification via bot `@TaskBellBot`.
   - Status koneksi: Belum Terhubung, Menunggu Verifikasi, Terhubung, Gagal.
   - Tombol Pesan Uji (*Test Message*).
   - Pengingat tenggat tugas satu arah (opsi: 15 menit, 30 menit, 1 jam sebelum tenggat).
   - Tombol putuskan koneksi dengan dialog konfirmasi aman.
   - **Keamanan Ketat**: Token bot Telegram tidak pernah ditampilkan atau diminta dari pengguna.
6. **Pengaturan Aplikasi Dasar**:
   - Preferensi tampilan (Terang / Gelap / Sistem), Pengaturan Zona Waktu pengguna (WIB/WITA/WIT/UTC), Format Tanggal, dan Profil ringkas.
   - Kontrol teknis backend mentah dihilangkan dari antarmuka pengguna biasa.
7. **Komponen Tanggal & Mock Data**:
   - Menggunakan komponen tanggal dinamis/relatif berbasis zona waktu pengguna (misal WIB).
   - Semua data contoh pada demonstrasi ditandai jelas sebagai `Mock Data / Demonstrasi`.

### Fitur Ditandai "Tahap Berikutnya / Post-MVP" (Di Luar MVP)
- Checklist / Subtasks bertingkat di dalam tugas.
- Pengulangan tugas otomatis (Recurring tasks: Harian/Mingguan/Bulanan).
- Morning Briefing & Weekly Review otomatis via bot Telegram.
- Pengingat berulang tugas terlambat (*overdue escalation & cooldowns*).
- Analitik statistik lanjutan & visualisasi grafik mendalam (Tab 'Statistik' di luar MVP).
- Widget Home Screen Android.
- Backup, Ekspor & Impor (CSV / JSON).
- Perintah bot Telegram interaktif dua arah (`/add`, `/done`, inline keyboard).

---

## 3. Spesifikasi Layar MVP (8 Layar)

### 3.1 Layar Masuk (Login)
- **Komponen**: Form email/nama pengguna, kata sandi dengan toggle intip sandi SVG, tombol 'Masuk Sekarang', alternatif login cepat, banner mode lokal informatif, link ke Registrasi.
- **State**: Default, Loading/Proses Masuk, Form Invalid (email/sandi kosong), Error kredensial salah, Mode offline / cache lokal informatif.

### 3.2 Layar Registrasi (Register)
- **Komponen**: Form nama lengkap, email validasi, kata sandi, Comic Meter Sandi, konfirmasi kata sandi, checkbox persetujuan S&K dengan touch target ≥48×48 px.
- **State**: Default, Validasi sandi tidak cocok, Loading pendaftaran, Berhasil/redirect.

### 3.3 Dashboard (Beranda)
- **Komponen**: Sapaan pengguna dinamis & tanggal hari ini (WIB) dengan tag Mock Data, CTA utama `+ Tambah Tugas Baru`, 4 kartu ringkasan tugas MVP (Total, Tertunda, Selesai, Lewat Tenggat), panel status Telegram bot dengan tombol tes notifikasi, daftar prioritas hari ini tanpa subtask, pintasan agenda dan tips pengingat bot MVP.
- **Navigasi Bawah**: 4 Tab MVP (Beranda, Tugas, Kalender, Pengaturan).

### 3.4 Daftar Tugas (Task List)
- **Komponen**: Kolom pencarian teks, bar filter (Semua, Hari Ini, Mendatang, Terlambat), filter kategori, badge demonstrasi, daftar kartu tugas tunggal dengan label prioritas, tenggat waktu, dan tombol aksi (Rincian, Edit, Hapus). Tanpa subtask / progress checklist.
- **Navigasi Bawah**: 4 Tab MVP.

### 3.5 Tambah / Edit Tugas
- **Komponen MVP Sederhana**:
  - Input Judul (wajib, max 80 karakter).
  - Input Deskripsi/Catatan (opsional).
  - Kategori chip pemilih (Kuliah, Kerja, Pribadi, Lainnya).
  - Tingkat Prioritas (Rendah, Sedang, Tinggi) dengan ikon SVG outline.
  - Tenggat Waktu: Pemilih Tanggal & Waktu (opsional).
  - Pengingat Telegram: Toggle aktif/nonaktif & dropdown opsi waktu (15 Menit, 30 Menit, 1 Jam Sebelum).
  - Tombol Simpan Tugas & Tombol Batal.
- **State**: Validasi error judul kosong, Loading simpan, Toast feedback sukses/gagal simpan, Draft lokal.

### 3.6 Kalender & Agenda
- **Komponen**: Header pemilih bulan & tahun dinamis dengan navigasi `<` dan `>`, indikator data demonstrasi kalender, selector tampilan agenda terisi vs agenda kosong (*empty state*), agenda tugas vertikal MVP tanpa subtask, tombol tambah tugas pada tanggal aktif.
- **Navigasi Bawah**: 4 Tab MVP.

### 3.7 Integrasi Telegram
- **Komponen**: Kartu status koneksi jelas (Terverifikasi oleh Server / Mock Data Simulasi), alur 3 langkah verifikasi menggunakan bot `@TaskBellBot`, tombol "Kirim Pesan Uji" dengan respons status 200 OK, preferensi pengingat tenggat (15 mnt, 30 mnt, 1 jam, 1 hari sebelum), tombol "Putuskan Sambungan Telegram" dengan modal konfirmasi.
- **Scope MVP Murni**: Morning Briefing dan Overdue escalation dipindahkan ke Post-MVP.

### 3.8 Pengaturan & Profil
- **Komponen**: Kartu profil pengguna (Nama, Email), status ringkas Chat ID Telegram terhubung (Mock Data), preferensi tema (Terang, Gelap, Sistem), Zona Waktu (WIB, dll.), Format penanggalan, Status Sinkronisasi Akun (Mock Data), Tombol Keluar Akun (Logout).
- **Navigasi Bawah**: 4 Tab MVP.
