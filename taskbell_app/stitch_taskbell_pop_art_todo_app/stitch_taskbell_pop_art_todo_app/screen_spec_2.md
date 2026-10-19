# Screen & Product Specification --- TaskBell

## 1. Ringkasan produk

TaskBell adalah aplikasi To-do List Android dengan pengingat dan
monitoring melalui Telegram. Produk mencakup pengelolaan tugas,
checklist, tugas berulang, statistik, offline mode, widget, dan
backup/ekspor.

### Konteks teknologi

-   Database PostgreSQL dengan nama database `taskbell` sudah dibuat
    pada lingkungan pengembangan pengguna.
-   Konteks proyek sebelumnya menggunakan Prisma dan `DATABASE_URL`;
    spesifikasi backend berikut mengasumsikan **Node.js + Prisma +
    PostgreSQL**.
-   Teknologi Android final belum dipilih dalam konteks yang tersedia.
    Tentukan sebelum implementasi APK, lalu pastikan dukungan offline,
    widget, notifikasi lokal, dan penyimpanan aman.
-   Dokumen ini adalah spesifikasi produk/implementasi, bukan klaim
    bahwa semua fitur sudah tersedia.

### Standar ikon UI (wajib)

-   Semua ikon antarmuka harus berupa **SVG**, baik sebagai aset `.svg` lokal
    maupun komponen SVG inline sesuai teknologi Android yang dipilih.
-   Jangan gunakan emoji, karakter Unicode sebagai ikon, icon font, atau PNG/JPG
    untuk ikon navigasi, aksi, status, notifikasi, grafik, maupun widget.
-   Gunakan gaya konsisten dengan design system comic-book TaskBell: bentuk
    sederhana, outline tegas, ukuran teratur, dan aksen warna seperlunya.
-   Tombol ikon harus memiliki label/accessibility description; status penting
    tetap disertai teks agar tidak bergantung pada bentuk atau warna saja.
-   Ilustrasi dekoratif dapat berupa SVG orisinal. Hindari SVG yang menyertakan
    skrip atau konten aktif yang tidak diperlukan.

## 2. Roadmap fitur

### MVP --- rilis pertama

1.  Autentikasi dan isolasi data per pengguna.
2.  CRUD tugas: judul, deskripsi, status, tenggat, prioritas, kategori.
3.  Pencarian, filter, sorting, dan tampilan tugas hari
    ini/mendatang/terlambat.
4.  Backend API dan PostgreSQL.
5.  Integrasi Telegram dasar: koneksi akun/chat yang terverifikasi,
    pesan uji, dan pengingat tenggat satu arah.
6.  Penjadwalan pengingat di server dan log pengiriman.
7.  Sinkronisasi online dasar, loading/error state, dan penanganan
    kegagalan API.
8.  Zona waktu pengguna serta pengaturan dasar.
9.  UI Android dengan state loading, empty, error, success.

**Tidak termasuk MVP:** analytics lengkap, recurring rules lanjutan,
offline write queue yang kompleks, widget, dan restore backup.

### Tahap berikutnya

1.  Morning Briefing Telegram dengan jadwal, zona waktu, dan hari aktif.
2.  Pengingat tugas terlambat dengan cooldown, batas jumlah, dan opsi
    berhenti.
3.  Subtasks/checklist dan progres checklist.
4.  Tugas berulang harian/mingguan/bulanan.
5.  Offline mode: cache lokal, antrean perubahan, retry, dan resolusi
    konflik dasar.
6.  Analytics produktivitas: tugas selesai, completion rate, backlog,
    dan tren keterlambatan.
7.  Weekly Review Telegram setiap akhir minggu, berisi tugas selesai,
    tugas tertunda, dan gambaran progres tanpa memberi skor yang
    menghakimi.

### Fitur lanjutan

1.  Widget Android dengan daftar tugas hari ini dan aksi cepat.
2.  Backup/restore dan ekspor CSV/JSON.
3.  Bot Telegram dua arah: `/today`, `/tasks`, `/upcoming`, `/add`,
    `/done`, `/stats`, `/help`.
4.  Resolusi konflik sinkronisasi yang lebih lengkap, filter statistik
    lanjutan, dan kontrol privasi widget.
5.  Pengulangan kustom, template tugas, dan pengingat yang lebih
    fleksibel jika dibutuhkan.

## 3. Alur pengguna utama

### A. Onboarding dan koneksi Telegram

1.  Pengguna membuka aplikasi dan membuat akun/login.
2.  Aplikasi menjelaskan fungsi inti dan meminta izin sistem hanya saat
    diperlukan.
3.  Pengguna membuka Integrasi Telegram.
4.  Server memulai proses linking yang aman; pengguna memulai bot dan
    menyelesaikan verifikasi chat.
5.  Server mengaitkan chat Telegram dengan akun aplikasi.
6.  Pengguna mengirim pesan uji; UI menampilkan sukses hanya jika server
    mengonfirmasi.
7.  Pengguna mengatur zona waktu, briefing, dan preferensi pengingat.

### B. Membuat dan menyelesaikan tugas

1.  Pengguna menekan Tambah Tugas.
2.  Mengisi judul, kategori, prioritas, tenggat, dan opsi pengingat.
3.  Jika dibutuhkan, menambahkan checklist/subtasks.
4.  Menyimpan tugas; aplikasi menampilkan status tersimpan atau menunggu
    sinkronisasi jika offline.
5.  Backend menyimpan perubahan dan membuat/memperbarui jadwal
    pengingat.
6.  Pengguna menandai tugas selesai dari aplikasi, widget, atau bot yang
    telah terverifikasi.
7.  Sistem membatalkan pengingat yang tidak lagi relevan dan memperbarui
    statistik.

### C. Morning Briefing

1.  Pengguna mengaktifkan briefing, menentukan jam, hari aktif, dan zona
    waktu.
2.  Scheduler server mengambil ringkasan tugas yang relevan untuk akun
    tersebut.
3.  Sistem mengirim satu pesan per jadwal/account sesuai preferensi.
4.  Status dicatat; kegagalan dicoba ulang dengan kebijakan terbatas.
5.  Pengguna dapat mematikan briefing kapan saja.

### D. Weekly Review Telegram

1.  Pengguna mengaktifkan laporan mingguan dan memilih hari/jam
    pengiriman serta zona waktu.
2.  Scheduler menghitung tugas yang selesai, masih tertunda, dan
    ringkasan progres dalam rentang minggu yang ditetapkan.
3.  Bot mengirim laporan ringkas dengan bahasa netral dan saran refleksi,
    bukan skor atau peringkat pengguna.
4.  Pengiriman dicatat dan dijaga agar tidak terkirim dua kali untuk
    periode laporan yang sama.
5.  Pengguna dapat mengubah jadwal atau menonaktifkan laporan kapan saja.

### E. Pengingat tugas terlambat

1.  Tugas melewati tenggat dan belum selesai.
2.  Scheduler mengevaluasi apakah tugas memenuhi aturan pengingat.
3.  Pengingat dikirim sesuai cooldown dan batas frekuensi.
4.  Ketika tugas selesai, diarsipkan, atau pengingat dinonaktifkan,
    pengingat lanjutan dibatalkan.
5.  Pengguna dapat memilih jeda atau menonaktifkan pengingat terlambat.

### F. Offline dan sinkronisasi

1.  Aplikasi memuat cache tugas yang tersimpan.
2.  Pengguna membuat atau mengubah tugas tanpa internet.
3.  Perubahan masuk antrean lokal dengan status "Menunggu sinkronisasi".
4.  Ketika koneksi kembali, aplikasi mengirim antrean secara idempoten.
5.  Server mengonfirmasi perubahan dan aplikasi memperbarui cache.
6.  Jika ada konflik, aplikasi menjelaskan konflik dan menyediakan
    pilihan; perubahan tidak boleh hilang diam-diam.
7.  Pengingat Telegram baru dijamin setelah perubahan berhasil diterima
    server.

### G. Backup dan ekspor

1.  Pengguna memilih seluruh data atau rentang tertentu.
2.  Memilih CSV untuk analisis tabel atau JSON untuk struktur
    data/checklist.
3.  Aplikasi menampilkan cakupan data dan memulai ekspor.
4.  Hasil disimpan/dibagikan melalui mekanisme sistem operasi yang aman.
5.  Restore, bila tersedia, menampilkan preview dan konfirmasi sebelum
    perubahan data.
6.  Token bot, session token, dan secret tidak pernah masuk ke file
    ekspor.

## 4. Spesifikasi layar

### 4.1 Dashboard

-   Sapaan/tanggal dan CTA Tambah Tugas.
-   Statistik: total, belum selesai, selesai, terlambat.
-   Prioritas hari ini, tugas mendatang, ringkasan progres mingguan.
-   Status Telegram dan status sinkronisasi.
-   Empty state jika belum ada tugas.
-   Aksi task row: buka detail, tandai selesai, edit.

### 4.2 Daftar tugas

-   Pencarian, filter status, kategori, prioritas, dan sorting.
-   Task row menampilkan tenggat, indikator reminder, dan progres
    checklist.
-   Aksi edit, selesai, arsip, dan hapus dengan konfirmasi.
-   State: loading, empty, no results, error, success.

### 4.3 Tambah/edit/detail tugas

Field: judul wajib, deskripsi, tenggat tanggal/waktu, prioritas,
kategori, checklist, aturan pengulangan, pengingat Telegram. - Validasi
field dan tenggat. - Subtask dapat ditambah, diedit, diurutkan, dan
ditandai selesai. - Tampilkan progres `x dari y selesai`. - Tugas
berulang memiliki pilihan mengubah kejadian ini saja atau seluruh
rangkaian jika model mendukung. - Jika offline, tunjukkan status
menunggu sinkronisasi. - Jika Telegram belum terhubung, jelaskan bahwa
pengingat Telegram belum bisa dijadwalkan.

### 4.4 Kalender/agenda

-   Kalender bulanan dan daftar agenda.
-   Pilih tanggal untuk melihat tugas.
-   Tugas tanpa tenggat tidak dipaksakan masuk kalender.
-   Mobile mengutamakan agenda vertikal.

### 4.5 Statistik

-   Rentang hari/minggu/bulan.
-   Jumlah tugas dibuat dan diselesaikan, completion rate, backlog, dan
    tugas terlambat.
-   Definisi metrik konsisten dan disertai label.
-   Jelaskan apakah data bersumber dari server atau mencakup perubahan
    lokal yang belum sinkron.

### 4.6 Integrasi Telegram

-   Status koneksi dan langkah linking.
-   Pesan uji.
-   Pengaturan Morning Briefing: aktif/nonaktif, waktu, hari, zona
    waktu.
-   Pengaturan pengingat tenggat dan overdue.
-   Putuskan koneksi dengan konfirmasi.
-   Jangan menampilkan token bot di aplikasi.

### 4.7 Pusat notifikasi

-   Status dijadwalkan, terkirim, gagal, retry, dan dibatalkan.
-   Filter status/rentang waktu.
-   Retry dengan idempotency agar tidak mengirim duplikat.
-   Pesan error ramah tanpa membocorkan detail rahasia.

### 4.8 Backup/ekspor

-   Pilih CSV/JSON, cakupan, dan rentang.
-   Progress, sukses/gagal, waktu ekspor terakhir.
-   Restore hanya jika memang diimplementasikan; perlu preview,
    validasi, dan konfirmasi.
-   Secret dan token dikecualikan.

### 4.9 Pengaturan

-   Tema, zona waktu, format tanggal, preferensi reminder.
-   Status sinkronisasi dan waktu sinkronisasi terakhir.
-   Pengaturan Telegram, backup, dan privasi widget.
-   Kontrol untuk jeda/menonaktifkan overdue reminder.

### 4.10 Widget Android

-   Widget kecil: jumlah dan beberapa tugas hari ini.
-   Widget sedang: daftar ringkas, checkbox cepat, tombol buka
    aplikasi/tambah tugas.
-   Data berasal dari cache lokal dan menunjukkan waktu pembaruan.
-   Jika aksi widget tidak bisa diselesaikan offline, antrekan dan beri
    status yang jujur.
-   Pertimbangkan privasi pada layar terkunci dan refresh sesuai batasan
    platform.

## 5. Bot Telegram

  Command       Perilaku
  ------------- ---------------------------------------
  `/start`      Memulai proses linking akun yang aman
  `/help`       Menampilkan perintah yang tersedia
  `/today`      Daftar tugas hari ini
  `/tasks`      Daftar tugas belum selesai
  `/upcoming`   Tugas mendatang
  `/add`        Alur tambah tugas bertahap
  `/done`       Pilih tugas dan tandai selesai
  `/stats`      Ringkasan produktivitas

Semua perintah harus memeriksa identitas chat yang telah terverifikasi.
Bot tidak boleh menerima `user_id` arbitrer dari pengguna sebagai bukti
kepemilikan. Gunakan tombol inline atau ID tugas yang terikat ke pemilik
dan lakukan konfirmasi untuk tindakan yang berpotensi salah sasaran.

## 6. Kebutuhan backend dan database

### Arsitektur

-   Android client: UI, cache lokal, antrean perubahan, notifikasi lokal
    opsional, widget.
-   REST API backend Node.js: autentikasi, otorisasi, validasi, task
    service, sync API, statistik, ekspor.
-   Prisma ORM untuk akses PostgreSQL.
-   PostgreSQL `taskbell` sebagai sumber data server.
-   Telegram Bot API dipanggil dari backend saja.
-   Background worker/scheduler untuk pengingat, briefing, overdue,
    retry, dan recurring task generation.
-   Job queue atau mekanisme penjadwalan persisten disarankan agar job
    tidak hilang saat server restart.

### Entitas/tabel yang disarankan

-   `users`: id, email/identifier, password hash bila autentikasi lokal,
    timezone, created_at.
-   `telegram_connections`: user_id, chat_id unik, status, linked_at,
    last_test_at. Token bot global disimpan di secret manager/env
    server, bukan per record dan bukan di client.
-   `tasks`: id, user_id, title, description, status, priority,
    category_id, due_at UTC nullable, timezone/context bila dibutuhkan,
    recurrence_rule nullable, created_at, updated_at, completed_at,
    archived_at, version.
-   `categories`: id, user_id, name, color token opsional.
-   `subtasks`: id, task_id, title, is_completed, position, created_at,
    updated_at.
-   `reminder_preferences`: user_id, morning_briefing_enabled,
    briefing_time, active_days, timezone, overdue_enabled,
    overdue_cooldown, max_overdue_reminders, weekly_review_enabled,
    weekly_review_day, weekly_review_time.
-   `reminder_jobs`: id, user_id, task_id nullable, job_type,
    scheduled_at, status, attempts, idempotency_key, last_error_safe,
    sent_at, period_start nullable, period_end nullable.
-   `notification_logs`: id, user_id, task_id nullable, channel, status,
    scheduled_at, sent_at, safe_error_code.
-   `sync_changes` atau `client_mutations`: idempotency_key, user_id,
    entity_type, entity_id, mutation_type, server_version, applied_at.
-   `recurrence_instances` atau kolom relasi series: recurring series
    dan occurrence individual, agar menyelesaikan satu kejadian tidak
    merusak seluruh seri.
-   `export_jobs` opsional untuk ekspor besar/asinkron.

### Aturan data

-   Semua query data pengguna wajib dibatasi dengan user_id dari sesi
    terautentikasi.
-   Gunakan foreign key, index pada `user_id`, `status`, `due_at`,
    `scheduled_at`, serta constraint yang mencegah chat Telegram
    terhubung ke lebih dari satu akun bila itu aturan produk.
-   Simpan timestamp server dalam UTC; tampilkan sesuai timezone
    pengguna.
-   Gunakan transaksi untuk menyimpan task dan memperbarui jadwal
    reminder.
-   Hapus/cancel job lama ketika due date atau status tugas berubah.
-   Idempotency key mencegah mutation dan pengiriman job diproses dua
    kali.

## 7. Keamanan Telegram dan aplikasi

1.  Token bot disimpan di environment secret/secret manager server;
    tidak boleh ada di APK, frontend, repository, log, atau file ekspor.
2.  Gunakan linking token sekali pakai, singkat masa berlakunya, dan
    terikat pada sesi pengguna untuk menghubungkan chat.
3.  Verifikasi webhook Telegram menggunakan secret token/header dan
    gunakan HTTPS.
4.  Otorisasi setiap command berdasarkan chat_id yang sudah ditautkan
    dan user_id terkait.
5.  Batasi laju command dan pengiriman pesan; validasi panjang/isi
    input.
6.  Jangan menampilkan stack trace, SQL, token, atau data pengguna lain
    pada error.
7.  Hash password dengan algoritma yang sesuai jika menggunakan
    autentikasi password; session/access token ditangani dengan aman.
8.  Ekspor hanya data milik pengguna yang meminta; token dan secret
    selalu dikecualikan.
9.  Widget menampilkan data minimum dan memiliki opsi privasi.
10. Catat audit event yang relevan tanpa merekam secret atau isi
    sensitif secara berlebihan.

## 8. Offline sync: kontrak perilaku

-   Simpan cache tugas lokal dan antrean mutation.
-   Beri setiap mutation ID/idempotency key.
-   Server mengembalikan versi/updated_at dan hasil mutation.
-   Retry dengan backoff; jangan retry tanpa batas.
-   Saat konflik, gunakan aturan per field atau tampilkan pilihan
    pengguna; jangan menimpa perubahan diam-diam.
-   Hapus item dari antrean hanya setelah server mengonfirmasi.
-   Telegram reminders/briefings memerlukan backend online; perubahan
    lokal belum menjadwalkan pengingat server.
-   Backup/ekspor harus menjelaskan apakah mencakup perubahan yang belum
    sinkron.

## 9. Kriteria penerimaan

### Ikon SVG

-   Semua ikon UI di layar utama, navigasi, tombol, status, notifikasi, dan widget
    menggunakan SVG; tidak ada emoji atau ikon Unicode sebagai pengganti ikon.
-   Ikon tampil tajam pada ukuran layar dan kepadatan piksel yang didukung serta
    tetap terbaca dalam tema terang dan gelap.
-   Tombol ikon dapat diakses melalui pembaca layar dan memiliki nama aksesibel;
    ikon dekoratif tidak diumumkan sebagai kontrol.
-   Status penting menyertakan teks dan tidak hanya mengandalkan ikon/warna.


### MVP

-   Pengguna dapat membuat, membaca, mengedit, menghapus, dan
    menyelesaikan tugas.
-   Pengguna A tidak dapat membaca atau mengubah tugas pengguna B.
-   Filter/pencarian dan status tugas konsisten setelah aplikasi dibuka
    kembali.
-   Akun Telegram dapat ditautkan melalui verifikasi dan pesan uji
    menghasilkan status yang benar.
-   Pengingat tenggat dikirim sesuai waktu dan zona waktu yang
    ditentukan.
-   Perubahan tenggat atau penyelesaian tugas memperbarui/membatalkan
    job yang relevan.
-   Status notifikasi tercatat dan kegagalan tidak ditampilkan sebagai
    sukses.
-   Token bot tidak ditemukan di APK, repository, client logs, atau
    ekspor.

### Tahap berikutnya

-   Morning Briefing hanya terkirim pada hari/waktu/zona waktu pilihan
    dan tidak duplikat untuk jadwal yang sama.
-   Overdue reminder mengikuti cooldown dan batas frekuensi; berhenti
    setelah tugas selesai atau dinonaktifkan.
-   Subtasks dapat dibuat, disusun, dan diselesaikan; progres akurat.
-   Recurring task membuat occurrence sesuai aturan dan tidak
    menduplikasi saat worker retry.
-   Saat offline, cache dapat dibaca dan perubahan diberi label menunggu
    sinkronisasi.
-   Setelah online, antrean tersinkron tanpa duplikasi; konflik
    ditangani eksplisit.
-   Analytics memakai definisi metrik yang terdokumentasi dan konsisten.
-   Weekly Review dikirim sesuai jadwal dan zona waktu, merangkum tugas
    selesai/tertunda untuk periode yang benar, dan tidak terkirim ganda
    saat worker melakukan retry.
-   Weekly Review dapat dinonaktifkan tanpa memengaruhi pengingat tugas
    lain.

### Fitur lanjutan

-   Widget menampilkan data cache yang benar, membuka tugas yang tepat,
    dan menunjukkan waktu refresh.
-   Ekspor CSV/JSON berisi data sesuai cakupan yang dipilih dan dapat
    dibuka dengan parser yang sesuai.
-   Restore tidak berjalan tanpa konfirmasi dan validasi.
-   Ekspor tidak mengandung token, session, atau secret.
-   Bot hanya dapat mengakses data akun yang terhubung; command tidak
    sah ditolak.

### Kualitas umum

-   UI dapat digunakan pada ukuran layar Android yang didukung dan skala
    teks sistem.
-   Semua kontrol utama memiliki feedback dan state
    loading/empty/error/success.
-   Aksesibilitas dasar: label, kontras, fokus/semantics, target sentuh
    memadai.
-   Test mencakup timezone, daylight-saving bila relevan, retry job,
    offline/online, akses lintas akun, dan duplikasi notifikasi.

## 10. Pertanyaan keputusan sebelum coding

-   Pilih teknologi Android (Flutter, Kotlin native, atau web wrapper).
-   Tentukan metode autentikasi.
-   Tentukan apakah MVP mendukung satu akun per instalasi atau
    multi-akun.
-   Tetapkan batas frekuensi overdue reminder dan default Morning
    Briefing.
-   Tentukan apakah backup MVP berupa ekspor saja atau juga restore.
