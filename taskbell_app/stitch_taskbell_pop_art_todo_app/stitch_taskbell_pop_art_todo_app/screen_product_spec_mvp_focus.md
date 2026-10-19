# Screen & Product Specification --- TaskBell Android (MVP Focus)

## 1. Ringkasan Produk

TaskBell adalah aplikasi To-do List Android dengan integrasi pengingat satu arah via Telegram bot, dibangun dengan arsitektur **Flutter (Frontend)** dan **Node.js + Prisma + PostgreSQL (Backend)**.

### Target Audiens
Pelajar, mahasiswa, dan individu yang membutuhkan manajemen tugas harian yang fokus, visual, dan andal dengan notifikasi langsung ke Telegram.

### Aturan Ikon & UI (Strict SVG-Only)
- **100% SVG Inline / Lokal**: Tidak ada emoji, karakter Unicode sebagai ikon, icon font, atau bitmap raster (PNG/JPG) untuk kontrol UI.
- Semua tombol aksi ber-SVG memiliki label aksesibilitas (`semanticsLabel` di Flutter / `aria-label`).
- Semua status penting disajikan dengan kombinasi ikon SVG dan teks eksplisit (tidak mengandalkan warna semata).

---

## 2. Cakupan Fitur (Scoping)

### Scope MVP (Rilis Pertama)
1. **Autentikasi Pengguna**: Registrasi akun baru, Masuk (Login), dan Keluar (Logout) dengan sesi terisolasi per akun.
2. **Manajemen Tugas (CRUD)**:
   - Buat tugas baru, lihat daftar & detail, edit, tandai selesai, dan hapus tugas.
   - Field tugas MVP: Judul (wajib), Deskripsi/Catatan (opsional), Kategori (Kuliah, Kerja, Pribadi, dll.), Prioritas (Rendah, Sedang, Tinggi), Tenggat Waktu (Tanggal & Jam opsional).
3. **Pencarian, Filter & Sorting**:
   - Filter cepat: Semua, Hari Ini, Mendatang, Terlambat, Selesai.
   - Filter kategori dan urutan tenggat waktu.
4. **Kalender & Agenda Dasar**:
   - Navigasi bulan dinamis (sebelumnya/berikutnya), penanda tanggal terpilih, dan tampilan agenda vertikal harian dengan state isi dan agenda kosong (*empty state*).
5. **Integrasi Telegram Dasar (Satu Arah)**:
   - Verifikasi sambungan bot Telegram dengan alur kode linking / One-Time Verification.
   - Status koneksi: Belum Terhubung, Menunggu Verifikasi, Terhubung, Gagal.
   - Tombol Pesan Uji (*Test Message*).
   - Pengingat tenggat tugas satu arah (misal: 15 menit, 30 menit, 1 jam sebelum tenggat).
   - Tombol putuskan koneksi dengan dialog konfirmasi aman.
   - **Keamanan Ketat**: Token bot Telegram tidak pernah ditampilkan atau diminta dari pengguna.
6. **Pengaturan Aplikasi Dasar**:
   - Preferensi tampilan (Terang / Gelap / Sistem), Pengaturan Zona Waktu pengguna (WIB/WITA/WIT/UTC), Format Tanggal, dan Profil ringkas.
   - **Catatan**: Rincian teknis backend seperti koneksi PostgreSQL mentah dihilangkan dari tampilan pengguna biasa.

### Fitur Ditandai "Tahap Berikutnya / Post-MVP" (Di Luar MVP)
- Checklist / Subtasks bertingkat di dalam tugas.
- Pengulangan tugas otomatis (Recurring tasks: Harian/Mingguan/Bulanan).
- Morning Briefing & Weekly Review otomatis via bot Telegram.
- Pengingat berulang tugas terlambat (*overdue escalation & cooldowns*).
- Analitik statistik lanjutan & grafik mendalam.
- Widget Home Screen Android.
- Backup, Ekspor & Impor (CSV / JSON).
- Perintah bot Telegram interaktif dua arah (`/add`, `/done`, inline keyboard).

---

## 3. Spesifikasi Layar & State Interaksi

### 3.1 Layar Masuk (Login)
- **Komponen**: Form email, kata sandi dengan toggle intip sandi SVG, tombol "Masuk Sekarang", link ke Registrasi.
- **State**: Default, Loading/Proses Masuk, Form Invalid (email/sandi kosong), Error kredensial salah, Mode offline / cache lokal informatif.

### 3.2 Layar Registrasi (Register)
- **Komponen**: Form nama lengkap, email validasi, kata sandi, konfirmasi kata sandi, checkbox persetujuan S&K.
- **State**: Default, Validasi sandi tidak cocok, Loading pendaftaran, Berhasil/redirect.

### 3.3 Dashboard (Beranda)
- **Komponen**: Sapaan pengguna dinamis & tanggal hari ini, CTA utama `+ Tambah Tugas Baru`, 4 kartu ringkasan tugas MVP (Total, Tertunda, Selesai, Terlambat), panel status Telegram bot, daftar prioritas hari ini, state empty jika tidak ada tugas.
- **Aksi Kontrol**: Klik kartu membuka filter terkait di Daftar Tugas; klik tugas membuka detail/edit; centang menyelesaikan tugas; tombol tes Telegram mengirim sinyal uji.

### 3.4 Daftar Tugas (Task List)
- **Komponen**: Kolom pencarian teks, bar filter (Semua, Hari Ini, Mendatang, Terlambat), filter kategori, daftar kartu tugas dengan label prioritas, tenggat waktu, dan tombol aksi (Rincian, Edit, Hapus).
- **State**: Loading skeleton, Daftar terisi, Hasil pencarian kosong (*No Search Results*), Empty state saat belum ada tugas, Konfirmasi hapus dialog.

### 3.5 Tambah / Edit Tugas
- **Komponen MVP Sederhana**:
  - Input Judul (wajib, max 80 karakter).
  - Input Deskripsi/Catatan (opsional).
  - Kategori chip pemilih (Kuliah, Kerja, Pribadi, dll.).
  - Tingkat Prioritas (Rendah, Sedang, Tinggi).
  - Tenggat Waktu: Pemilih Tanggal & Waktu (opsional).
  - Pengingat Telegram: Toggle aktif/nonaktif & dropdown opsi waktu (hanya jika Telegram terhubung).
  - Tombol Simpan Tugas & Tombol Batal.
- **State**: Validasi error judul kosong, Validasi tenggat lampau, Loading simpan, Toast feedback sukses/gagal simpan.

### 3.6 Kalender & Agenda
- **Komponen**: Header pemilih bulan & tahun dinamis dengan navigasi `<` dan `>`, grid hari dalam bulan, indikator tugas pada tanggal, agenda vertikal tugas di tanggal aktif, tombol tambah tugas pada tanggal aktif.
- **State**: Tanggal dengan tugas, Tanggal kosong tanpa tugas (*Empty Agenda State* dengan ilustrasi komik ramah).

### 3.7 Integrasi Telegram
- **Komponen**: Kartu status koneksi jelas (Belum Terhubung / Terhubung), alur 3 langkah verifikasi menggunakan bot `@TaskBellBot`, tombol "Kirim Pesan Uji", preferensi pengingat tenggat (15 mnt, 30 mnt, 1 jam sebelum), tombol "Putuskan Sambungan" dengan modal konfirmasi.
- **State**: Menunggu verifikasi (kode verifikasi aktif), Terhubung (sukses 200 OK), Gagal verifikasi/timeout, Pesan uji terkirim feedback.

### 3.8 Pengaturan & Profil
- **Komponen**: Kartu profil pengguna (Nama, Email), Status ringkas Telegram terhubung, Preferensi tema (Terang, Gelap, Sistem), Zona Waktu (WIB, dll.), Format penanggalan, Tombol Keluar Akun (Logout).
- **Perubahan Penting**: Menghilangkan kontrol teknis database PostgreSQL langsung yang tidak relevan bagi pengguna akhir.
