# Screen & Product Specification --- TaskBell Android (MVP Focus Final)

## 1. Ringkasan Produk

TaskBell adalah aplikasi To-do List Android dengan integrasi pengingat satu arah via Telegram bot, dibangun dengan arsitektur teknologi final:
- **Frontend**: Flutter / Dart (Android mobile-first, safe area, adaptive keyboard, strict SVG-only)
- **Backend**: Node.js + Prisma ORM + PostgreSQL (database `taskbell`)

### Target Audiens
Pelajar, mahasiswa, dan individu yang membutuhkan manajemen tugas harian yang fokus, visual, dan andal dengan notifikasi langsung ke Telegram.

### Aturan Ikon & UI (Strict SVG-Only — Standar Mutlak)
- **100% SVG Inline / Lokal**: Seluruh 8 file HTML bebas dari referensi Material Symbols, icon fonts, emoji, atau karakter Unicode yang dipakai sebagai kontrol UI.
- Semua tombol aksi ber-SVG memiliki label aksesibilitas (`semanticsLabel` di Flutter / `aria-label`).
- Semua status disajikan dengan kombinasi ikon SVG dan teks eksplisit (tidak mengandalkan warna semata).

---

## 2. Cakupan Fitur MVP (Scope Terkunci)

### Scope MVP (Rilis Pertama)
1. **Autentikasi Pengguna**: Registrasi akun baru, Masuk (Login), dan Keluar (Logout) dengan sesi terisolasi per akun.
2. **Manajemen Tugas Tunggal (CRUD)**:
   - Buat tugas baru, lihat daftar & detail ringkas, edit, tandai selesai, dan hapus tugas.
   - Field tugas MVP: Judul (wajib, max 80 karakter), Deskripsi/Catatan (opsional), Kategori chip (Kuliah, Kerja, Pribadi, Lainnya), Tingkat Prioritas (Rendah, Sedang, Tinggi), Tenggat Waktu (Tanggal dinamis & Jam opsional).
3. **Pencarian, Filter & Sorting**:
   - Filter cepat: Semua, Hari Ini, Mendatang, Terlambat.
   - Filter kategori dan urutan tenggat waktu.
4. **Kalender & Agenda Dinamis**:
   - Navigasi bulan dinamis (`<` dan `>`), penanda tanggal terpilih, selector agenda terisi vs agenda kosong (*empty state* ramah gaya komik), serta tombol tambah tugas pada tanggal terpilih. Bebas dari penguncian tanggal statis 2024.
5. **Integrasi Telegram Satu Arah**:
   - Status koneksi jelas: Belum Terhubung, Menunggu Verifikasi, Terhubung (Mock Data / Server 200 OK), Gagal.
   - Alur pairing 3 langkah via bot resmi `@TaskBellBot` dengan 6-digit One-Time Token.
   - Tombol Pesan Uji (*Test Message*).
   - Pengingat tenggat tugas satu arah (15 menit, 30 menit, 1 jam, 1 hari sebelum).
   - Tombol putuskan koneksi dengan dialog konfirmasi aman.
   - **Keamanan Ketat**: Token bot Telegram tidak pernah ditampilkan atau diminta dari pengguna biasa.
6. **Pengaturan & Profil Pengguna**:
   - Profil ringkas (Nama, Email, Akun Gratis MVP), Chat ID Telegram terhubung, preferensi tampilan (Terang / Gelap / Sistem), Pengaturan Zona Waktu (WIB / UTC+7), Format Tanggal Dinamis, Status Sinkronisasi Akun (Mock Data), Tombol Keluar Akun.
   - Tidak ada kontrol teknis basis data PostgreSQL mentah.
7. **Komponen Tanggal & Mock Data**:
   - Menggunakan komponen tanggal dinamis/relatif berbasis zona waktu WIB.
   - Seluruh data contoh pada mockup/demonstrasi ditandai jelas sebagai `Mock Data / Demonstrasi`.

### Fitur Ditandai "Roadmap Post-MVP" (Di Luar MVP)
- Checklist / Subtasks bertingkat di dalam tugas.
- Pengulangan tugas otomatis (Recurring tasks: Harian/Mingguan/Bulanan).
- Morning Briefing & Weekly Review otomatis via bot Telegram.
- Pengingat berulang tugas terlambat (*overdue escalation & cooldowns*).
- Analitik statistik lanjutan & visualisasi grafik mendalam (Tab 'Statistik').
- Widget Home Screen Android.
- Backup, Ekspor & Impor (CSV / JSON).
- Perintah bot Telegram interaktif dua arah (`/add`, `/done`, inline keyboard).

---

## 3. Spesifikasi 8 Layar MVP

| No | Layar | Elemen Kunci MVP | Catatan SVG & Tanggal |
|---|---|---|---|
| 1 | **Dashboard (Beranda)** | Sapaan 'Hari Ini (WIB)' [Mock Data], 4 Kartu Metrik [Mock Data / Demonstrasi], Bot Telegram Aktif, 2 Kartu Prioritas Hari Ini tanpa subtasks, Bottom Nav 4-tab. | 100% SVG inline, bebas font icons & emoji. |
| 2 | **Tambah / Edit Tugas** | Input Judul (counter 80 char), Catatan opsional, Chip Kategori, Prioritas 3-level, Pemilih Tanggal Dinamis & Jam, Toggle Pengingat Telegram. | Bebas input subtask & recurring. |
| 3 | **Kalender & Agenda** | Header bulan dinamis navigasi `<` dan `>`, Tab Hari Ini (3 Tugas) vs Besok (Kosong), Agenda vertikal tunggal, Empty state komik, Tombol tambah tugas tanggal terpilih. | Bebas tanggal statis Oktober 2024. |
| 4 | **Daftar Tugas** | Search bar komik 'Cari tugas...', filter chips, 3 kartu tugas tunggal dengan aksi lengkap (Rincian, Edit, Hapus), status Dinamis. | Tanpa subtask counter / progress bar. |
| 5 | **Masuk Akun (Login)** | Hero lonceng komik, Input Email & Sandi, Toggle intip sandi SVG, Banner Mode Lokal, Tombol Masuk, Badge MVP READY. | 100% SVG inline. |
| 6 | **Registrasi Akun** | Balon dialog komik, Nama Lengkap, Email, Sandi + Comic Meter Sandi, Checkbox S&K touch-target >= 48px, Tombol Daftar, Badge TaskBell MVP. | 100% SVG inline. |
| 7 | **Integrasi Telegram** | Status Terverifikasi [Mock Data], Tombol Kirim Pesan Uji (200 OK), Alur 3 Langkah Bot Pairing, Pilihan Waktu Pengingat Tenggat, Tombol Putuskan Sambungan. | Bebas Morning Briefing & token bot server. |
| 8 | **Pengaturan & Profil** | Profil Pengguna, Chat ID Telegram terhubung, Preferensi Tampilan, Zona Waktu WIB, Format Kalender Dinamis, Status Sinkronisasi [Mock Data], Tombol Keluar Akun. | Bebas kontrol PostgreSQL mentah & briefing. |
