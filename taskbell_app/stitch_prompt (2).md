# Google Stitch --- TaskBell Android To-do List

## 1. Product

-   **Nama:** TaskBell
-   **Platform:** Aplikasi Android yang akan dikemas sebagai APK.
-   **Tujuan:** Mengelola tugas, tenggat, checklist, tugas berulang,
    pengingat Telegram, serta pemantauan produktivitas.
-   **Pengguna:** Pelajar, mahasiswa, dan individu yang ingin mengatur
    aktivitas pribadi.
-   **Bahasa UI:** Bahasa Indonesia.
-   **Arah implementasi backend:** Node.js + Prisma + PostgreSQL
    (database `taskbell`, sesuai rencana proyek). Teknologi Android
    final masih perlu ditetapkan saat implementasi.
-   **Deliverable desain:** layar hi-fi dan alur navigasi; dokumen ini
    bukan file proyek native Google Stitch.

## 2. Visual direction

Gunakan gaya yang terinspirasi dari screenshot comic-book/pop-art: warna
cerah, outline hitam tegas, panel ekspresif, aksen halftone, speech
bubble, burst radial, bintang dan petir. Buat identitas dan ilustrasi
orisinal. Jangan menyalin logo, karakter, atau aset spesifik dari
referensi.

Gaya harus ekspresif tetapi tetap mengutamakan produktivitas: dekorasi
ditempatkan di header, kartu ringkasan, onboarding, dan empty state;
daftar tugas, formulir, grafik, serta pengaturan tetap bersih dan mudah
dibaca.

### Aturan ikon wajib
Semua ikon UI harus berupa **SVG**—gunakan SVG inline atau aset `.svg` lokal
yang konsisten. Jangan gunakan emoji, ikon Unicode, icon font, atau PNG/JPG
sebagai ikon antarmuka. Gunakan ikon SVG dengan stroke tegas, geometri sederhana,
dan gaya konsisten dengan outline comic-book TaskBell. Ikon boleh memakai aksen
warna dari design system, tetapi harus tetap terbaca pada tema terang/gelap.
Ikon tombol harus mempunyai label atau accessible name; status penting harus
menampilkan ikon SVG bersama teks, bukan ikon saja. Ilustrasi dekoratif juga
sebaiknya dibuat sebagai SVG orisinal bila sesuai.

Gunakan token dari `design_system.md`. Warna awal: biru `#347BE5`,
kuning `#FFB900`, oranye `#FF8A00`, merah-magenta `#E91E4B`, ungu
`#8429D8`, latar ivory `#FFF9EC`, permukaan putih, teks/border
`#171717`. Anggap nilai ini sebagai titik awal visual.

## 3. Information architecture

Navigasi utama: - Beranda - Tugas - Kalender - Statistik - Pengaturan

Di Pengaturan tersedia Integrasi Telegram, Pusat Notifikasi, Backup &
Ekspor, dan preferensi aplikasi. Detail tugas dapat dibuka dari daftar,
kalender, widget, dan tautan/aksi Telegram.

## 4. Screens to design

### Screen 1 --- Dashboard

-   Sapaan, tanggal, dan tombol `+ Tambah Tugas`.
-   Kartu ringkasan: total tugas, belum selesai, selesai, terlambat.
-   Daftar prioritas hari ini dan tugas mendatang.
-   Ringkasan progres minggu ini.
-   Status integrasi Telegram.
-   Akses ke briefing, kalender, dan statistik.
-   Empty state yang ramah dengan ilustrasi comic orisinal.

### Screen 2 --- Daftar dan detail tugas

-   Pencarian, filter Semua/Hari Ini/Mendatang/Terlambat/Selesai, filter
    kategori dan prioritas, sorting.
-   Task row menampilkan judul, tenggat, prioritas, kategori, status,
    indikator pengingat, dan progres subtasks.
-   Detail tugas: deskripsi, checklist/subtasks, riwayat perubahan
    relevan, jadwal, aturan pengulangan, dan pengingat.
-   Aksi tandai selesai, edit, arsipkan, hapus dengan konfirmasi.
-   Status checklist terlihat tanpa bergantung pada warna saja.

### Screen 3 --- Tambah/Edit tugas

Field: - Judul wajib; deskripsi opsional. - Tenggat tanggal/waktu
opsional. - Prioritas rendah/sedang/tinggi dan kategori. -
Subtasks/checklist yang dapat ditambah, diurutkan, dan ditandai
selesai. - Pengingat Telegram dan waktu pengingat. - Pengulangan: tidak
berulang, harian, mingguan, bulanan, atau aturan kustom sederhana. -
Pilihan simpan sebagai tugas berulang atau hanya satu kejadian jika
relevan. Validasi jelas; perubahan offline diberi label menunggu
sinkronisasi.

### Screen 4 --- Kalender dan agenda

-   Kalender bulanan dan agenda vertikal.
-   Penanda tugas berdasarkan tanggal, dengan label/ikon selain warna.
-   Pilih tanggal untuk melihat tugas; tambah tugas dengan tanggal
    terpilih.
-   Mobile mengutamakan agenda yang mudah digulir.

### Screen 5 --- Statistik produktivitas

-   Tugas selesai per hari/minggu/bulan.
-   Completion rate dengan definisi yang jelas.
-   Tugas terlambat dan tren backlog.
-   Grafik sederhana, rentang tanggal, dan ringkasan teks.
-   Bedakan data lokal yang belum sinkron dari data yang telah tersimpan
    di server.

### Screen 6 --- Integrasi Telegram

-   Panduan menghubungkan bot dan chat secara aman.
-   Status Belum terhubung/Menghubungkan/Terhubung/Perlu perhatian.
-   Tombol Kirim Pesan Uji dan Putuskan Koneksi.
-   Preferensi Morning Briefing, jam pengiriman, zona waktu, hari aktif,
    Weekly Review, pengingat tenggat, dan pengingat tugas terlambat.
-   Token bot hanya dikonfigurasi di server/secret manager; jangan
    tampilkan atau simpan di APK.
-   Tampilkan hanya status pengiriman yang didukung hasil server.

### Screen 7 --- Pusat Notifikasi

-   Daftar pengingat terjadwal, terkirim, gagal, dan menunggu.
-   Tampilkan tugas, waktu terjadwal, waktu kirim, status, dan alasan
    yang aman.
-   Filter rentang waktu/status dan aksi coba lagi jika valid.
-   Hindari retry ganda yang menghasilkan notifikasi duplikat.

### Screen 8 --- Backup & Ekspor

-   Ekspor data tugas/checklist dalam CSV dan JSON.
-   Backup lokal dan/atau server sesuai dukungan implementasi.
-   Pilih rentang atau seluruh data; tampilkan waktu backup terakhir.
-   Konfirmasi sebelum menimpa/memulihkan data.
-   Jelaskan data apa yang disertakan dan jangan pernah mengekspor token
    atau secret Telegram.
-   Tampilkan progres, hasil, dan kegagalan ekspor dengan jelas.

### Screen 9 --- Pengaturan dan sinkronisasi

-   Tema terang/gelap/sistem, zona waktu, format tanggal, preferensi
    pengingat, dan pengaturan privasi.
-   Status sinkronisasi: Sinkron, Menunggu, Sedang menyinkronkan, Gagal.
-   Waktu sinkronisasi terakhir dan tombol coba lagi.
-   Pengguna dapat memilih apakah tugas baru memakai pengingat default.

### Screen 10 --- Widget Android (preview)

-   Rancang widget layar utama yang ringkas: tugas hari ini, checkbox
    cepat, dan tombol buka aplikasi/tambah tugas.
-   Sediakan variasi kecil dan sedang jika platform mendukung.
-   Widget harus tetap berguna saat offline dengan data cache dan
    menunjukkan waktu pembaruan secara halus.
-   Jangan menampilkan data privat di layar terkunci tanpa pertimbangan
    privasi.

## 5. Feature roadmap

### MVP --- wajib untuk rilis pertama

-   CRUD tugas, status selesai, kategori, prioritas, tenggat,
    pencarian/filter.
-   Autentikasi dan data pengguna terisolasi.
-   Integrasi Telegram satu arah untuk pengingat dan pesan uji.
-   Pengingat tenggat dasar.
-   Database PostgreSQL melalui backend API.
-   Status pengiriman dan log notifikasi.
-   Sinkronisasi online dasar dan penanganan error.
-   UI responsif, state loading/empty/error/success, dan pengaturan zona
    waktu.

### Tahap berikutnya

-   Morning Briefing Telegram dengan jadwal pilihan.
-   Weekly Review Telegram mingguan berisi tugas selesai, tugas tertunda,
    dan gambaran progres dengan nada reflektif, bukan penilaian.
-   Pengingat tugas terlambat dengan batas frekuensi dan opsi berhenti.
-   Subtasks/checklist.
-   Tugas berulang.
-   Offline mode dengan antrean perubahan dan sinkronisasi saat koneksi
    kembali.
-   Analytics produktivitas.

### Fitur lanjutan

-   Widget Android dengan data cache dan aksi cepat.
-   Backup dan restore terkontrol serta ekspor CSV/JSON.
-   Perintah bot untuk `/today`, `/tasks`, `/upcoming`, `/add`, `/done`,
    `/stats`, dan `/help`.
-   Konflik sinkronisasi yang lebih lengkap, pengingat berulang
    lanjutan, dan pengaturan privasi widget.

## 6. Telegram bot interaction

Rancang contoh alur bot yang generik: - `/start` --- memulai alur
koneksi akun. - `/help` --- bantuan. - `/today` --- tugas hari ini. -
`/tasks` --- tugas belum selesai. - `/upcoming` --- tugas mendatang. -
`/add` --- alur tambah tugas. - `/done` --- pilih tugas lalu
konfirmasi. - `/stats` --- ringkasan produktivitas.

Semua perintah adalah rancangan, bukan klaim fitur sudah aktif. Akses
data harus terikat pada akun yang terverifikasi. Untuk tindakan
perubahan data, gunakan pilihan tugas yang jelas dan konfirmasi yang
sesuai.

## 7. Offline and synchronization UX

-   Cache tugas yang relevan agar daftar dan detail dapat dibuka
    offline.
-   Aksi offline masuk antrean lokal dan diberi label
    `Menunggu sinkronisasi`.
-   Tampilkan indikator koneksi dan waktu sinkronisasi terakhir.
-   Jangan menyatakan pengingat Telegram berhasil dijadwalkan saat
    perubahan masih lokal dan belum dikirim ke server.
-   Jika ada konflik edit, tampilkan solusi yang dapat dipahami; jangan
    menghapus perubahan pengguna diam-diam.
-   Jelaskan bahwa notifikasi Telegram dan briefing terjadwal memerlukan
    koneksi server.

## 8. Visual components

Semua ikon pada seluruh layar, navigasi, tombol, status, grafik, notifikasi,
widget, dan ilustrasi kecil wajib menggunakan SVG. Jangan gunakan emoji, ikon
Unicode, icon font, atau raster image sebagai pengganti ikon. Terapkan aturan
aksesibilitas dan konsistensi ikon pada `design_system.md`.

-   Tombol primary/secondary/destructive/loading/disabled.
-   Task card, checklist row, priority badge, category chip, due-date
    label.
-   Summary card, analytics chart, calendar day, agenda row.
-   Telegram connection panel, notification log, sync status.
-   Backup/export dialog, progress indicator, toast, confirm dialog.
-   Empty/error/loading states. Gunakan outline 2 px, shadow offset
    secara selektif, dan aksen halftone hanya pada area dekoratif.

## 9. Accessibility and interaction

-   Semua kontrol yang tampak aktif harus memiliki aksi yang jelas.
-   Label form selalu terlihat; validasi dekat dengan field terkait.
-   Status tidak dibedakan berdasarkan warna saja.
-   Target sentuh sekitar 44×44 px atau lebih.
-   Fokus terlihat, navigasi aksesibel, kontras memadai, dukung reduced
    motion.
-   Konfirmasi penghapusan dan pemulihan data.
-   Status pengiriman dan sinkronisasi harus berasal dari state yang
    nyata.

## 10. Deliverable

Buat desain hi-fi konsisten untuk seluruh layar dan alur: buat tugas →
atur pengingat → terima Telegram → kelola checklist → lihat statistik →
gunakan offline → sinkronkan → ekspor data. Dokumen ini adalah
prompt/spesifikasi Markdown untuk Google Stitch, bukan proyek native
Stitch.
