# PRD --- TaskBell

**Product Requirements Document**
**Versi:** 1.1
**Status:** Update untuk Arsitektur Hybrid Offline-First
**Platform utama:** Android
**Backend:** Node.js, Prisma ORM, PostgreSQL
**Integrasi utama:** Telegram Bot API
**Arsitektur:** Hybrid Offline-First (Local SQLite + Server Sync)

------------------------------------------------------------------------

## 1. Ringkasan Produk

**TaskBell** adalah aplikasi pengelola tugas untuk Android yang dirancang dengan arsitektur **Hybrid Offline-First**. Pengguna dapat mencatat dan mengelola aktivitas sehari-hari secara penuh tanpa koneksi internet menggunakan penyimpanan lokal SQLite. Saat koneksi tersedia, aplikasi secara otomatis menyinkronkan data dua arah dengan backend. Selain pengingat di aplikasi, TaskBell terhubung dengan Telegram untuk pemberitahuan tenggat dan laporan produktivitas.

TaskBell menggabungkan pengelolaan tugas yang sederhana dengan pengingat terjadwal dan analitik yang informatif. Aplikasi harus terasa cepat, jelas, responsif, dan mudah digunakan, dengan bahasa yang netral serta tidak menghakimi pengguna.

### 1.1 Masalah yang ingin diselesaikan
-   Tugas mudah terlupakan.
-   Pengguna kesulitan melihat prioritas dan tenggat terdekat.
-   Koneksi internet yang tidak stabil seringkali menghalangi pengguna mencatat atau mengubah tugas.
-   Kebutuhan akan sinkronisasi data antar perangkat di masa depan.

### 1.2 Solusi
TaskBell menyediakan daftar tugas (lokal & tersinkron), kategori, prioritas, tenggat, pencarian/filter, notifikasi lokal, pengingat Telegram berbasis server, analitik, serta backup data. Arsitektur offline-first menjamin aplikasi tetap fungsional di segala kondisi jaringan.

------------------------------------------------------------------------

## 2. Arsitektur Sinkronisasi (Hybrid Offline-First)

Aplikasi mengikuti prinsip berikut untuk sinkronisasi data:
1.  **Local First**: Semua aksi CRUD (Create, Read, Update, Delete) terjadi secara instan di SQLite lokal melalui Riverpod `StateNotifier`.
2.  **Mutation Queue**: Setiap perubahan lokal disimpan dalam antrean sinkronisasi (sync queue) untuk diunggah ke server saat koneksi stabil.
3.  **Idempotency**: Setiap operasi sinkronisasi memiliki ID unik agar tidak ada duplikasi data meskipun terjadi *retry* akibat kegagalan jaringan.
4.  **Conflict Resolution**: Konflik ditangani dengan aturan *Last-Writer-Wins* yang disempurnakan dengan *timestamp* (updated_at) dari sisi server. Jika terjadi konflik pada level record yang sama, aplikasi akan memprioritaskan data terbaru.
5.  **Soft Delete**: Penghapusan tugas dilakukan secara *soft delete* (flag `is_deleted`) untuk memastikan sinkronisasi penghapusan yang konsisten antara klien dan server.

------------------------------------------------------------------------

## 3. roadmap Pengembangan

... (Tabel dan isi PRD lainnya tetap relevan, disesuaikan dengan fokus Offline-First) ...

------------------------------------------------------------------------

## 2. Tujuan dan Ukuran Keberhasilan

### 2.1 Tujuan produk

1.  Memudahkan pengguna membuat, mengubah, menyelesaikan, dan menghapus
    tugas.
2.  Membantu pengguna menentukan pekerjaan berdasarkan prioritas dan
    tenggat.
3.  Mengirim notifikasi Telegram yang tepat waktu, aman, dan tidak
    duplikatif.
4.  Menampilkan ringkasan kemajuan secara jelas tanpa memberi penilaian
    yang menghakimi.
5.  Menjaga data tiap pengguna tetap terisolasi dan tersinkron dengan
    andal.
6.  Menyediakan pengalaman yang dapat berkembang dari MVP menjadi
    aplikasi yang lebih lengkap.

### 2.2 Indikator keberhasilan

-   Pengguna dapat menyelesaikan alur membuat hingga menandai tugas
    selesai tanpa kebingungan.
-   Pengingat yang memenuhi syarat dikirim pada waktu yang benar sesuai
    zona waktu pengguna.
-   Sistem mencegah pengiriman pesan terjadwal yang sama secara tidak
    sengaja.
-   Perubahan tugas tidak muncul pada akun pengguna lain.
-   Kegagalan jaringan atau Telegram tercatat dan dapat ditangani dengan
    retry yang aman.
-   Pengguna dapat menghubungkan dan memutuskan Telegram tanpa
    membagikan token bot.
-   Analitik menampilkan data yang konsisten dengan catatan tugas.

Target numerik untuk metrik seperti retensi, latensi, dan tingkat
keberhasilan pengiriman ditetapkan setelah tersedia data penggunaan dan
pengujian awal.

------------------------------------------------------------------------

## 3. Target Pengguna dan Kebutuhan

### 3.1 Target pengguna

-   Pelajar dan mahasiswa yang mengatur tugas akademik, ujian, proyek,
    dan kegiatan organisasi.
-   Pengguna yang ingin mengatur pekerjaan pribadi berdasarkan prioritas
    dan tanggal.
-   Pengguna Telegram yang ingin menerima pengingat tanpa harus terus
    membuka aplikasi.

### 3.2 Kebutuhan utama

-   Membuat tugas dengan cepat.
-   Mengetahui tugas yang harus dikerjakan hari ini dan tenggat yang
    mendekat.
-   Menyaring tugas berdasarkan status, kategori, prioritas, atau
    tanggal.
-   Menerima pengingat Telegram yang relevan.
-   Memahami kemajuan dan pekerjaan yang masih tertunda.
-   Tetap dapat mencatat perubahan saat offline, dengan status
    sinkronisasi yang jelas ketika fitur offline tersedia.

------------------------------------------------------------------------

## 4. Ruang Lingkup dan Prioritas

Pengembangan dibagi menjadi tiga tahap. Fitur tahap lanjutan tidak boleh
menghambat penyelesaian dan kestabilan MVP.

### Tahap 1 --- MVP

-   Registrasi, login, logout, dan manajemen sesi.
-   Data tugas terisolasi per akun.
-   CRUD tugas: membuat, melihat, mengubah, menghapus, dan menandai
    selesai.
-   Kategori, prioritas, tenggat, dan zona waktu pengguna.
-   Pencarian dan filter dasar.
-   Tampilan daftar tugas dan kalender dasar.
-   Pengaturan dan koneksi Telegram.
-   Tombol untuk menguji koneksi/pengiriman pesan Telegram.
-   Pengingat tenggat satu arah dari aplikasi ke Telegram.
-   Backend API, PostgreSQL, pencatatan status pengiriman notifikasi.
-   Keadaan UI untuk loading, kosong, error, offline, dan sukses.

### Tahap 2 --- Pengembangan berikutnya

-   **Morning Briefing:** ringkasan tugas harian yang dikirim pada
    jadwal pilihan pengguna.
-   **Overdue Escalation:** pengingat untuk tugas yang melewati tenggat,
    dengan jeda dan batas frekuensi.
-   **Weekly Review:** ringkasan mingguan tentang tugas selesai dan yang
    masih tertunda.
-   Analitik produktivitas.
-   Tugas berulang.
-   Subtask dan checklist.
-   Cache offline dan antrean sinkronisasi perubahan.

### Tahap 3 --- Fitur lanjutan

-   Widget Android dengan ringkasan tugas dan tindakan cepat.
-   Backup dan restore data.
-   Ekspor data ke CSV dan JSON.
-   Perintah bot Telegram dua arah.
-   Penanganan konflik sinkronisasi yang lebih lengkap.

------------------------------------------------------------------------

## 5. Persyaratan Fungsional

### 5.1 Akun dan autentikasi --- MVP

-   Pengguna dapat membuat akun, login, dan logout.
-   Endpoint yang membutuhkan autentikasi harus memverifikasi sesi atau
    token yang valid.
-   Pengguna hanya dapat membaca dan mengubah data miliknya.
-   Kata sandi tidak boleh disimpan dalam bentuk teks biasa.
-   Pesan error autentikasi harus jelas, tetapi tidak membocorkan
    informasi sensitif.
-   Sediakan validasi input di sisi aplikasi dan server.

**Kriteria penerimaan** - Pengguna yang belum login tidak dapat
mengakses data privat. - Pengguna A tidak dapat membaca, mengubah, atau
menghapus tugas milik pengguna B dengan mengganti ID pada request. -
Kata sandi tersimpan menggunakan metode hashing yang sesuai. - Logout
mengakhiri sesi pengguna pada server.

### 5.2 Manajemen tugas --- MVP

Setiap tugas setidaknya memiliki: - ID unik. - Pemilik/pengguna. - Judul
wajib. - Deskripsi opsional. - Status: belum selesai atau selesai. -
Prioritas. - Kategori opsional. - Tenggat opsional. - Waktu pembuatan
dan pembaruan. - Waktu penyelesaian bila telah selesai.

Pengguna dapat: - Membuat tugas. - Melihat detail dan daftar tugas. -
Mengubah atribut tugas. - Menandai tugas selesai atau mengembalikannya
ke status belum selesai. - Menghapus tugas dengan konfirmasi yang
sesuai. - Mencari tugas berdasarkan judul atau deskripsi. - Memfilter
tugas berdasarkan status, kategori, prioritas, dan rentang tanggal.

**Kriteria penerimaan** - Judul kosong ditolak dan input divalidasi. -
Perubahan tersimpan di backend dan ditampilkan konsisten setelah data
dimuat ulang. - Tugas yang selesai tidak lagi menerima pengingat aktif
untuk tenggat tersebut. - Hasil pencarian dan filter sesuai dengan
kriteria yang dipilih. - Penghapusan tidak menghapus data milik pengguna
lain.

### 5.3 Kategori dan prioritas --- MVP

-   Pengguna dapat memilih kategori untuk mengelompokkan tugas.
-   Prioritas minimal terdiri dari rendah, sedang, dan tinggi.
-   Prioritas ditampilkan dengan label teks yang jelas, bukan hanya
    warna.
-   Pengguna dapat memfilter daftar berdasarkan kategori dan prioritas.

### 5.4 Tenggat, kalender, dan zona waktu --- MVP

-   Tugas dapat memiliki tanggal dan waktu tenggat.
-   Tenggat boleh tidak diisi.
-   Kalender dasar menampilkan tugas berdasarkan tanggal.
-   Sistem menyimpan waktu secara konsisten dan menampilkan waktu sesuai
    zona waktu pengguna.
-   Zona waktu digunakan untuk pengingat terjadwal dan ringkasan harian.

**Kriteria penerimaan** - Waktu yang ditampilkan konsisten setelah
aplikasi dibuka di perangkat atau sesi yang berbeda. - Perubahan zona
waktu pengguna diterapkan pada jadwal notifikasi berikutnya. - Tugas
tanpa tenggat tidak memicu pengingat tenggat.

### 5.5 Integrasi Telegram --- MVP

-   Pengguna dapat memulai proses menghubungkan akun Telegram dari
    aplikasi.
-   Proses pengaitan harus menggunakan token penghubung sementara yang
    aman dan memiliki masa berlaku.
-   Pengguna dapat mengirim pesan uji untuk memastikan integrasi
    bekerja.
-   Pengguna dapat memutuskan koneksi Telegram.
-   Bot mengirim pengingat tenggat yang telah memenuhi aturan
    pengiriman.
-   Status pengiriman dicatat, misalnya menunggu, terkirim, gagal, atau
    dicoba ulang.
-   Token bot Telegram hanya disimpan di server sebagai secret; token
    tidak boleh ditanam di APK atau disimpan di repository.

**Kriteria penerimaan** - Pengguna tidak dianggap terhubung sebelum
proses pengaitan diverifikasi server. - Token penghubung hanya dapat
digunakan sesuai masa berlaku dan tidak dapat digunakan berulang kali
jika alur dirancang sekali pakai. - Pesan uji memberikan hasil sukses
atau error yang bisa dipahami. - Setelah Telegram diputus, pengingat
berikutnya tidak dikirim ke chat tersebut. - Kegagalan Telegram tidak
menyebabkan kehilangan data tugas.

### 5.6 Pengingat tenggat --- MVP

-   Pengguna dapat mengaktifkan atau menonaktifkan pengingat.
-   Sistem menjadwalkan pengingat berdasarkan tenggat dan zona waktu
    pengguna.
-   Sistem memeriksa ulang status tugas sebelum mengirim pesan.
-   Pengingat untuk tugas yang telah selesai atau dihapus harus
    dibatalkan atau dilewati.
-   Pengiriman harus idempoten agar retry tidak menyebabkan pesan
    duplikat.

**Kriteria penerimaan** - Tugas selesai sebelum jadwal pengingat tidak
menerima pengingat aktif tersebut. - Tugas yang dihapus tidak menerima
pengingat. - Retry setelah kegagalan tidak membuat pengiriman yang sama
berulang tanpa kontrol. - Waktu pengingat mengikuti zona waktu pengguna.

### 5.7 Morning Briefing --- Tahap 2

-   Pengguna dapat mengaktifkan atau menonaktifkan ringkasan pagi.
-   Pengguna dapat memilih waktu pengiriman, hari aktif, dan zona waktu.
-   Pesan berisi ringkasan jumlah tugas hari ini, tugas prioritas
    tinggi, dan tenggat terdekat.
-   Ringkasan tidak menyertakan data pengguna lain.
-   Sistem mencegah pesan briefing yang sama dikirim lebih dari sekali
    untuk jadwal yang sama.

### 5.8 Overdue Escalation --- Tahap 2

-   Pengguna dapat mengaktifkan atau menonaktifkan pengingat tugas
    terlambat.
-   Frekuensi dan jeda pengingat harus dibatasi.
-   Sistem memeriksa status terbaru sebelum setiap pengiriman.
-   Pengingat berhenti setelah tugas selesai, dihapus, atau fitur
    dinonaktifkan.
-   Tidak boleh mengirim pesan terus-menerus atau membuat pengguna
    menerima spam.

### 5.9 Weekly Review --- Tahap 2

-   Pengguna dapat memilih apakah ingin menerima ringkasan mingguan.
-   Ringkasan berisi jumlah tugas yang selesai, tugas yang masih
    tertunda, dan gambaran kemajuan secara netral.
-   Jadwal mengikuti zona waktu dan hari pengiriman yang dipilih.
-   Pesan tidak menggunakan bahasa yang mempermalukan atau menghakimi
    pengguna.

### 5.10 Analitik produktivitas --- Tahap 2

-   Menampilkan jumlah tugas selesai.
-   Menampilkan tingkat penyelesaian dengan definisi perhitungan yang
    terdokumentasi.
-   Menampilkan jumlah tugas tertunda.
-   Menampilkan tren tugas terlambat dari waktu ke waktu.
-   Rentang tanggal analitik harus dapat dipilih.
-   Grafik harus memiliki label, legenda, dan keadaan kosong.
-   Data analitik harus berasal dari data tugas pengguna yang sedang
    login.

### 5.11 Tugas berulang --- Tahap 2

-   Pengguna dapat mengatur pola pengulangan, misalnya harian, mingguan,
    atau pola terjadwal yang didukung.
-   Pengguna dapat menentukan tanggal mulai dan, bila relevan, tanggal
    akhir.
-   Penyelesaian satu kejadian tidak boleh tanpa sengaja menyelesaikan
    seluruh kejadian berikutnya.
-   Aturan untuk mengubah atau menghapus rangkaian tugas harus
    dijelaskan pada UI.

### 5.12 Subtask dan checklist --- Tahap 2

-   Tugas dapat memiliki beberapa subtask/checklist.
-   Pengguna dapat menambah, mengubah, mengurutkan, dan menandai item
    selesai.
-   Progres checklist ditampilkan secara ringkas.
-   Perilaku status tugas induk ketika semua subtask selesai harus
    ditentukan secara konsisten dan dijelaskan di UI.

### 5.13 Offline dan sinkronisasi --- Tahap 2

-   Aplikasi dapat menyimpan cache tugas yang telah dimuat.
-   Perubahan yang dibuat offline masuk ke antrean sinkronisasi lokal.
-   UI membedakan status tersimpan lokal, menunggu sinkronisasi,
    tersinkron, dan gagal.
-   Sinkronisasi memakai ID operasi/idempotensi untuk menghindari
    perubahan ganda.
-   Konflik antara perubahan lokal dan server harus ditangani dengan
    aturan eksplisit, bukan diam-diam menimpa data.
-   Jika sinkronisasi gagal, perubahan tetap dipertahankan secara lokal
    sampai berhasil atau pengguna mendapat penjelasan yang jelas.

### 5.14 Widget Android --- Tahap 3

-   Widget menampilkan ringkasan tugas yang relevan.
-   Tindakan cepat dibatasi pada fungsi yang aman dan jelas, misalnya
    membuka tugas atau menandai selesai.
-   Sediakan opsi privasi agar isi tugas sensitif tidak harus
    ditampilkan pada layar utama.
-   Widget memperbarui data mengikuti mekanisme refresh Android yang
    didukung.

### 5.15 Backup, restore, dan ekspor --- Tahap 3

-   Pengguna dapat mengekspor data miliknya ke CSV dan JSON.
-   Backup harus menjelaskan data apa yang disertakan.
-   Restore harus memvalidasi file dan menampilkan konfirmasi sebelum
    menerapkan perubahan.
-   File ekspor tidak boleh menyertakan secret server, token bot, atau
    data pengguna lain.
-   Kesalahan file harus menghasilkan pesan yang dapat dipahami tanpa
    merusak data yang sudah ada.

### 5.16 Perintah Telegram dua arah --- Tahap 3

Perintah awal yang direncanakan: - `/today` --- menampilkan tugas hari
ini. - `/tasks` --- menampilkan daftar tugas yang relevan. - `/upcoming`
--- menampilkan tenggat mendatang. - `/add` --- memulai alur penambahan
tugas. - `/done` --- memulai alur menandai tugas selesai. - `/stats` ---
menampilkan ringkasan statistik. - `/help` --- menampilkan bantuan
perintah.

Bot hanya memproses perintah dari chat Telegram yang telah diverifikasi
dan ditautkan ke akun pengguna. Input perintah harus divalidasi,
dibatasi lajunya, dan tidak boleh mengakses data pengguna lain.

------------------------------------------------------------------------

## 6. Alur Pengguna Utama

### 6.1 Alur penggunaan dasar

1.  Pengguna membuka aplikasi.
2.  Pengguna login atau membuat akun.
3.  Pengguna masuk ke halaman daftar tugas.
4.  Pengguna membuat tugas dengan judul dan atribut opsional.
5.  Tugas disimpan dan muncul di daftar.
6.  Pengguna mencari, memfilter, mengubah, atau menandai tugas selesai.
7.  Jika tenggat dan pengingat tersedia, sistem menjadwalkan notifikasi
    sesuai pengaturan.
8.  Pengguna dapat membuka pengaturan untuk menghubungkan Telegram dan
    mengirim pesan uji.

### 6.2 Alur menghubungkan Telegram

1.  Pengguna memilih **Hubungkan Telegram**.
2.  Server membuat token penghubung sementara.
3.  Aplikasi menampilkan instruksi untuk membuka bot dan menyelesaikan
    proses pengaitan.
4.  Server memverifikasi interaksi Telegram serta token.
5.  Server mengaitkan chat Telegram yang terverifikasi ke akun pengguna.
6.  Aplikasi menampilkan status terhubung.
7.  Pengguna mengirim pesan uji atau memutus koneksi kapan saja.

Detail UX dan mekanisme deep link dapat disesuaikan dengan implementasi
Telegram Bot API, tetapi token penghubung wajib bersifat sementara dan
diverifikasi server.

### 6.3 Alur pengingat

1.  Pengguna menyimpan tugas dengan tenggat dan pengingat aktif.
2.  Backend menyimpan tugas dan menjadwalkan pekerjaan notifikasi.
3.  Saat jadwal tiba, worker membaca ulang data dan status tugas.
4.  Jika tugas masih aktif dan pengguna masih terhubung, pesan dikirim.
5.  Sistem mencatat hasil pengiriman.
6.  Jika terjadi kegagalan sementara, sistem melakukan retry terbatas
    dengan backoff.
7.  Jika tugas selesai, dihapus, atau Telegram diputus, pengingat yang
    tidak lagi relevan dilewati atau dibatalkan.

------------------------------------------------------------------------

## 7. Persyaratan UI/UX dan Design System

### 7.1 Arah visual

-   Gaya visual **comic-book/pop-art** yang terarah dan modern.
-   Tampilan harus terasa ekspresif tetapi tetap rapi, terbaca, dan
    tidak berlebihan.
-   Gunakan hierarki visual yang jelas untuk judul, informasi tugas,
    tenggat, prioritas, dan tindakan utama.
-   Mendukung tema terang dan gelap.
-   Layout responsif terhadap ukuran layar Android yang didukung.
-   Hindari tampilan yang terlalu padat, ornamen yang mengganggu, dan
    animasi berlebihan.

### 7.2 Aturan ikon --- wajib

-   **Semua ikon antarmuka harus menggunakan SVG.**
-   Gunakan SVG inline atau file lokal `.svg`.
-   Jangan menggunakan emoji, karakter Unicode sebagai pengganti ikon,
    icon font, PNG, atau JPG untuk ikon UI.
-   Ikon memakai gaya outline comic-book yang konsisten, dengan ukuran
    standar 16 px, 20 px, atau 24 px.
-   SVG harus memiliki `viewBox` yang sesuai, bentuk yang konsisten, dan
    tetap terbaca pada tema terang maupun gelap.
-   Kontrol interaktif yang hanya menampilkan ikon harus memiliki
    accessible label/content description.
-   Ikon dekoratif harus disembunyikan dari pembaca layar; informasi
    penting tidak boleh disampaikan melalui ikon atau warna saja.
-   Aset SVG harus lokal atau inline dan tidak boleh menjalankan script
    yang tidak aman.

### 7.3 Komponen UI minimum

-   Navigasi utama.
-   Kartu atau baris tugas.
-   Form tambah/edit tugas.
-   Filter dan pencarian.
-   Pemilih tanggal/waktu.
-   Label status dan prioritas.
-   Dialog konfirmasi penghapusan.
-   Pengaturan Telegram dan status koneksi.
-   Komponen ringkasan/analitik.
-   Indikator loading, empty state, error state, offline state, dan sync
    state.

### 7.4 Aksesibilitas dan kegunaan

-   Teks memiliki kontras yang memadai pada kedua tema.
-   Status penting selalu disertai label teks.
-   Area sentuh sesuai pedoman kegunaan perangkat seluler.
-   Form memiliki label dan pesan validasi yang jelas.
-   Animasi tidak boleh menghalangi tugas utama.
-   Informasi sensitif tidak ditampilkan pada notifikasi atau widget
    secara berlebihan.

------------------------------------------------------------------------

## 8. Persyaratan Teknis dan Arsitektur

### 8.1 Arsitektur tingkat tinggi

-   **Android app:** antarmuka, validasi awal, cache lokal, dan antrean
    sinkronisasi saat fitur offline dikembangkan.
-   **Backend API:** autentikasi, otorisasi, logika tugas, pengaturan,
    dan integrasi Telegram.
-   **PostgreSQL:** penyimpanan data utama.
-   **Prisma ORM:** akses database dan pengelolaan skema/migrasi.
-   **Background worker/scheduler:** pemrosesan pengingat, briefing,
    review, dan retry.
-   **Telegram Bot API:** pengiriman pesan dan penerimaan
    update/perintah bila fitur dua arah tersedia.

Teknologi framework Android belum ditetapkan dalam dokumen ini dan perlu
diputuskan sebelum implementasi UI dimulai.

### 8.2 Modul backend

-   Auth dan session management.
-   User preferences dan timezone.
-   Task, category, priority, recurring task, dan checklist.
-   Telegram linking dan bot integration.
-   Notification scheduler, delivery log, retry, dan idempotency.
-   Analytics.
-   Sync API dan operasi idempotensi.
-   Backup/export untuk tahap lanjutan.

### 8.3 Entitas database yang direncanakan

Nama tabel dapat berubah saat desain skema final, tetapi model data
minimal mencakup:

-   `users`: identitas akun dan informasi autentikasi.
-   `user_preferences`: tema, zona waktu, dan preferensi notifikasi.
-   `tasks`: judul, deskripsi, status, prioritas, kategori, tenggat,
    pemilik, dan timestamp.
-   `categories`: kategori yang tersedia untuk pengguna.
-   `telegram_connections`: relasi akun pengguna dengan chat Telegram
    terverifikasi.
-   `telegram_link_tokens`: token penghubung sementara, masa berlaku,
    dan status penggunaan.
-   `notification_jobs`: jadwal pekerjaan notifikasi dan statusnya.
-   `notification_logs`: jenis pesan, waktu, hasil pengiriman, dan
    informasi error yang aman.
-   `recurrence_rules`: aturan pengulangan untuk tugas.
-   `subtasks`: item checklist di bawah tugas induk.
-   `sync_operations`: ID operasi idempoten dan status sinkronisasi,
    bila fitur offline diterapkan.

Relasi antar-entitas wajib mempertahankan kepemilikan data. Penghapusan
akun dan tugas perlu memiliki aturan retensi/penghapusan yang jelas.

### 8.4 API

-   API menggunakan HTTPS di lingkungan produksi.
-   Endpoint privat wajib melakukan autentikasi dan otorisasi berbasis
    pemilik data.
-   Validasi dilakukan di server untuk semua input yang memengaruhi data
    atau tindakan.
-   Respons error memiliki format yang konsisten dan tidak membocorkan
    stack trace atau secret.
-   Operasi penting seperti pembuatan tugas dan penjadwalan notifikasi
    harus konsisten bila satu langkah gagal.
-   Versi API perlu dipertimbangkan agar perubahan di masa depan tidak
    merusak aplikasi yang sudah terpasang.

Rincian endpoint dan kontrak request/response dibuat dalam spesifikasi
API terpisah sebelum implementasi.

------------------------------------------------------------------------

## 9. Keamanan dan Privasi

-   Simpan kata sandi menggunakan hashing yang sesuai.
-   Gunakan HTTPS untuk komunikasi produksi.
-   Simpan token bot Telegram dan secret lain hanya pada konfigurasi
    rahasia server, bukan APK, source code, log, atau file ekspor.
-   Token penghubung Telegram harus acak, memiliki masa berlaku, sekali
    pakai bila memungkinkan, dan tidak dapat ditebak.
-   Verifikasi webhook Telegram menggunakan mekanisme secret yang sesuai
    dan batasi akses endpoint webhook.
-   Validasi identitas chat Telegram sebelum menerima perintah atau
    mengirim data privat.
-   Terapkan rate limiting pada autentikasi, endpoint sensitif,
    pengaitan Telegram, dan perintah bot.
-   Jangan mencatat kata sandi, token, atau isi sensitif secara tidak
    perlu.
-   Pisahkan data berdasarkan pemilik di semua query dan operasi.
-   Gunakan prinsip least privilege untuk akun database dan secret
    aplikasi.
-   Sediakan cara memutus integrasi Telegram dan menghapus data sesuai
    kebijakan produk.
-   Tentukan kebijakan backup, retensi log, dan penghapusan akun sebelum
    rilis publik.

------------------------------------------------------------------------

## 10. Keandalan, Kinerja, dan Observabilitas

### 10.1 Keandalan notifikasi

-   Pekerjaan terjadwal harus tersimpan secara persisten, bukan hanya
    bergantung pada proses aplikasi yang sedang berjalan.
-   Setiap pengiriman memiliki kunci idempotensi atau identitas unik.
-   Retry memakai exponential backoff atau strategi backoff yang setara,
    dengan batas percobaan.
-   Pesan yang gagal permanen ditandai dan tidak diulang tanpa batas.
-   Scheduler memeriksa ulang data terbaru sebelum mengirim pesan.
-   Log mencatat status, waktu, dan kode error yang aman untuk
    debugging.

### 10.2 Kinerja

-   Daftar tugas harus mendukung pagination atau strategi pemuatan yang
    sesuai ketika jumlah data meningkat.
-   Query harus memanfaatkan indeks yang sesuai, terutama untuk pemilik,
    status, dan tenggat.
-   Operasi yang lambat atau eksternal, seperti pengiriman Telegram,
    tidak boleh membuat request CRUD utama menggantung terlalu lama.
-   Target latensi final ditentukan dan diuji setelah platform serta
    lingkungan deployment dipilih.

### 10.3 Observabilitas

-   Catat error backend, kegagalan scheduler, dan kegagalan integrasi
    Telegram.
-   Sediakan health check untuk layanan backend.
-   Log tidak boleh berisi secret atau data pribadi yang tidak
    diperlukan.
-   Gunakan metrik untuk memantau jumlah pesan berhasil/gagal dan jumlah
    retry.

------------------------------------------------------------------------

## 11. Keadaan UI dan Penanganan Error

Setiap layar yang memuat data harus mempertimbangkan keadaan berikut: -
**Loading:** data sedang dimuat. - **Empty:** belum ada tugas atau belum
ada hasil pencarian. - **Error:** data gagal dimuat atau disimpan,
dengan tindakan yang jelas. - **Offline:** koneksi tidak tersedia; pada
MVP tampilkan status dan sediakan retry, sedangkan penyimpanan offline
penuh masuk Tahap 2. - **Pending sync:** perubahan menunggu sinkronisasi
(Tahap 2). - **Success:** operasi berhasil, misalnya tugas tersimpan
atau Telegram terhubung. - **Permission/configuration issue:** izin atau
konfigurasi yang diperlukan belum tersedia.

Error harus menggunakan bahasa yang membantu pengguna mengambil langkah
berikutnya, bukan sekadar menampilkan kode teknis.

------------------------------------------------------------------------

## 12. Pengujian dan Kriteria Rilis

### 12.1 Pengujian wajib

-   Unit test untuk validasi tugas, aturan prioritas, penghitungan
    analitik, dan aturan jadwal.
-   Integration test untuk API dan database.
-   Test otorisasi untuk memastikan isolasi data antarpengguna.
-   Test integrasi Telegram dengan mock/stub dan pengujian terkontrol.
-   Test idempotensi dan retry untuk mencegah pesan duplikat.
-   Test zona waktu, perubahan waktu, tenggat kosong, tugas selesai, dan
    tugas dihapus.
-   Test UI untuk alur login, CRUD tugas, pencarian/filter, serta
    koneksi Telegram.
-   Test aksesibilitas label ikon dan kontras tema terang/gelap.
-   Test migrasi database dan pemulihan dari kegagalan yang relevan.

### 12.2 Kriteria MVP siap dirilis

MVP dapat dianggap siap untuk pengujian pengguna ketika: 1. Alur
autentikasi dan CRUD tugas bekerja end-to-end. 2. Data terisolasi per
pengguna pada API dan database. 3. Pencarian, filter, kategori,
prioritas, tenggat, dan kalender dasar berfungsi. 4. Pengaitan Telegram
dan pesan uji dapat diselesaikan dengan aman. 5. Pengingat tenggat
mengikuti zona waktu dan tidak mengirim pesan untuk tugas yang tidak
lagi aktif. 6. Kegagalan notifikasi dicatat dan retry dibatasi. 7. UI
menyediakan loading, empty, error, dan offline state yang jelas. 8.
Semua ikon UI memakai SVG sesuai aturan desain. 9. Tidak ada secret yang
tertanam di APK atau repository. 10. Pengujian utama dan pemeriksaan
keamanan dasar lulus.

------------------------------------------------------------------------

## 13. Risiko dan Mitigasi

  -----------------------------------------------------------------------
  Risiko                  Dampak                  Mitigasi
  ----------------------- ----------------------- -----------------------
  Pesan Telegram duplikat Pengguna terganggu dan  Idempotensi, log
                          kehilangan kepercayaan  pengiriman, dan
                                                  pemeriksaan status
                                                  sebelum retry

  Token bot bocor         Integrasi dapat         Secret hanya di server,
                          disalahgunakan          rotasi token, dan
                                                  larangan logging secret

  Data lintas pengguna    Pelanggaran privasi     Otorisasi di server dan
  terbuka                                         pengujian isolasi data

  Zona waktu salah        Pengingat terlambat     Penyimpanan waktu
                          atau terlalu cepat      konsisten, preferensi
                                                  timezone, dan test
                                                  lintas zona

  Telegram API gagal      Pengingat tidak         Retry terbatas, status
                          terkirim                gagal, dan log yang
                                                  dapat dipantau

  Perubahan offline       Data hilang atau        ID operasi, aturan
  bertabrakan             tertimpa                konflik eksplisit, dan
                                                  UI status sinkronisasi

  Fitur terlalu banyak di MVP lambat selesai      Pengembangan
  awal                                            berdasarkan tiga tahap
                                                  prioritas

  Widget membocorkan isi  Informasi terlihat pada Opsi privasi dan
  tugas                   layar utama             tampilan ringkas yang
                                                  dapat dikonfigurasi
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 14. Di Luar Ruang Lingkup MVP

Hal-hal berikut tidak wajib untuk rilis MVP: - Kolaborasi tugas antar
pengguna. - Chat internal. - Integrasi kalender pihak ketiga. - Perintah
Telegram dua arah. - Widget Android. - Backup/restore dan ekspor. -
Sinkronisasi offline penuh. - Analitik lanjutan. - Sistem gamifikasi
atau skor yang menghakimi pengguna.

Fitur di luar ruang lingkup dapat dipertimbangkan setelah MVP
tervalidasi, tanpa mengubah prioritas tahap yang sudah ditetapkan secara
diam-diam.

------------------------------------------------------------------------

## 15. Asumsi dan Keputusan yang Masih Perlu Ditetapkan

Sebelum implementasi final, tim perlu menetapkan: 1. Framework Android
yang digunakan. 2. Metode autentikasi dan manajemen sesi/token API. 3.
Detail desain endpoint dan kontrak API. 4. Provider hosting backend,
PostgreSQL, scheduler, dan penyimpanan secret. 5. Jadwal default dan
opsi konfigurasi pengingat tenggat. 6. Definisi matematis tingkat
penyelesaian dan periode analitik. 7. Aturan detail konflik untuk
sinkronisasi offline. 8. Kebijakan retensi log, backup, penghapusan
akun, dan privasi. 9. Target perangkat/versi Android minimum. 10. Batas
panjang pesan dan format pesan Telegram.

Asumsi teknis yang digunakan saat ini adalah backend Node.js dengan
Prisma ORM dan PostgreSQL, dengan nama database pengembangan `taskbell`.
Pilihan framework Android belum dikunci oleh PRD ini.

------------------------------------------------------------------------

## 16. Glosarium

-   **MVP:** versi awal dengan fitur inti yang siap diuji.
-   **CRUD:** create, read, update, delete --- membuat, membaca,
    memperbarui, dan menghapus data.
-   **Idempotensi:** pengulangan operasi yang sama tidak menimbulkan
    efek ganda.
-   **Scheduler/worker:** layanan backend yang menjalankan pekerjaan
    terjadwal di luar request utama.
-   **Timezone:** zona waktu yang digunakan untuk menampilkan tanggal
    dan menentukan jadwal.
-   **Offline sync:** mekanisme menyimpan perubahan lokal dan
    menyelaraskannya dengan server ketika koneksi tersedia.
-   **SVG:** format grafis vektor yang diwajibkan untuk seluruh ikon
    antarmuka TaskBell.

------------------------------------------------------------------------

## 17. Ringkasan Keputusan Produk

TaskBell dimulai sebagai aplikasi Android pengelola tugas dengan backend
Node.js, Prisma, PostgreSQL, dan integrasi Telegram satu arah untuk
pengingat tenggat. MVP berfokus pada autentikasi, isolasi data, CRUD
tugas, kategori/prioritas, tenggat, pencarian/filter, kalender dasar,
koneksi Telegram, serta notifikasi yang aman dan tidak duplikatif.

Tahap berikutnya menambahkan Morning Briefing, Overdue Escalation,
Weekly Review, analitik, tugas berulang, checklist, dan sinkronisasi
offline. Tahap lanjutan menambahkan widget Android, backup/restore,
ekspor CSV/JSON, serta perintah Telegram dua arah.

Semua ikon UI wajib memakai SVG lokal atau inline dengan gaya comic-book
outline yang konsisten, aksesibilitas yang baik, dan keterbacaan pada
tema terang maupun gelap.
