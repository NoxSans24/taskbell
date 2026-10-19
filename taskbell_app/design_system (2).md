# Design System --- TaskBell Android

## 1. Prinsip visual

TaskBell memakai gaya comic-book/pop-art yang diadaptasi dari referensi:
ekspresif, kontras, panel tegas, aksen halftone dan ilustrasi kartun
orisinal. Karena aplikasi berfokus pada produktivitas, dekorasi harus
hemat dan tidak mengganggu pemindaian tugas, grafik, checklist, atau
formulir.

Nilai token adalah perkiraan awal berdasarkan screenshot, bukan
pengukuran presisi.

## 2. Warna

  Token        HEX         Penggunaan
  ------------ ----------- --------------------------
  Primary      `#347BE5`   CTA, tautan, fokus utama
  Secondary    `#FFB900`   Highlight dan aksen
  Orange       `#FF8A00`   Aksen pendamping
  Red accent   `#E91E4B`   Peringatan/aksen
  Purple       `#8429D8`   Aksen statistik
  Background   `#FFF9EC`   Latar terang
  Surface      `#FFFFFF`   Kartu, dialog, input
  Text         `#171717`   Teks utama
  Text muted   `#555555`   Teks pendukung
  Border       `#171717`   Outline
  Success      `#197447`   Status berhasil
  Warning      `#8A4B00`   Perlu perhatian
  Error        `#B42335`   Gagal/error
  Info         `#245CB5`   Informasi

Status harus menyertakan teks/ikon, tidak hanya warna. Periksa kontras
WCAG AA, khususnya teks kecil pada warna kuning/oranye dan di atas
halftone. Dark mode menggunakan token semantik tersendiri, bukan inversi
otomatis.

## 3. Tipografi

-   Display/headings: `Baloo 2` atau sans-serif rounded tebal.
-   Body/UI: `DM Sans` atau `Inter`.
-   Display font hanya untuk judul singkat; gunakan font UI untuk
    daftar, formulir, angka statistik, dan keterangan.

  Style          Ukuran     Weight   Line height
  --------- ----------- ---------- -------------
  Display     34--42 px        800           1.1
  H1          28--34 px        800          1.15
  H2          22--26 px   700--800           1.2
  H3          18--20 px        700          1.25
  Body        14--16 px   400--500     1.45--1.6
  Label       12--14 px   600--700           1.3
  Caption     11--12 px   400--500           1.4

## 4. Spacing

Gunakan skala kelipatan 4 px: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 px. -
Padding card: 16--24 px. - Jarak antarbagian: 24--32 px. - Jarak baris
tugas/checklist: 8--12 px. - Form mobile satu kolom dengan ruang sentuh
memadai.

## 5. Radius, border, elevation

-   Radius kecil 6 px; sedang 10 px; besar 16 px; pill 999 px.
-   Outline standar 2 px solid `#171717`.
-   Focus ring 3 px yang jelas dengan offset 2 px.
-   Shadow komik selektif: offset sekitar `3px 3px 0 #171717`.
-   Hindari shadow blur berat dan glassmorphism yang tidak didukung
    referensi.

## 6. Ilustrasi dan tekstur

-   Speech bubble untuk tips/empty state, bukan paragraf panjang.
-   Burst radial, petir, bintang, awan, dan halftone sebagai aksen.
-   Buat aset SVG orisinal; jangan menyalin logo/karakter/aset spesifik
    dari referensi.
-   Hindari tekstur di belakang teks kecil, grafik, checklist, dan form.
-   Statistik harus tetap mudah dipahami meski aksen warna
    dinonaktifkan.

## 7. Iconography

**Semua ikon antarmuka TaskBell wajib menggunakan SVG.** Jangan gunakan emoji,
karakter Unicode sebagai ikon, ikon berbasis font, atau gambar raster (PNG/JPG)
untuk menggantikan ikon UI. Gunakan SVG orisinal atau pustaka ikon SVG yang
berlisensi sesuai; gaya garis tegas dan konsisten dengan outline komik TaskBell.

- Ukuran standar: 16, 20, dan 24 px; ikon navigasi/aksi utama dapat memakai
  24 px atau sesuai grid komponen.
- Utamakan `stroke` konsisten, bentuk sederhana, dan `viewBox` yang rapi.
  Ikon boleh memakai warna aksen/pengisian terbatas, tetapi tetap jelas dalam
  tema terang maupun gelap.
- Simpan aset sebagai berkas `.svg` terorganisasi (misalnya `assets/icons/`)
  atau gunakan komponen SVG inline yang dapat dipelihara. Hindari SVG dengan
  skrip, event handler tertanam, atau sumber eksternal yang tidak tepercaya.
- Ikon dekoratif disembunyikan dari pembaca layar; ikon tombol wajib memiliki
  label teks atau accessible name yang bermakna.
- Status sinkronisasi, notifikasi, prioritas, dan checklist harus memakai ikon
  SVG **dan** teks; jangan mengandalkan ikon atau warna saja.
- Untuk grafik, gunakan SVG bila ikon/ilustrasi diperlukan, tetapi jangan
  mengganti data grafik dengan ilustrasi dekoratif.

## 8. Komponen

### Buttons

Primary biru; secondary putih/ivory dengan outline hitam; destructive
merah; disabled dengan kontras yang tetap cukup. Tinggi 44--48 px dan
target sentuh minimal 44×44 px. State: default, hover/focus, pressed,
loading, disabled.

### Task card

Informasi urut: status, judul, tenggat, kategori/prioritas, progres
checklist, indikator pengingat/sinkronisasi, menu aksi. Detail sekunder
pindah ke baris kedua pada layar kecil.

### Checklist/subtask row

Checkbox jelas, judul, status, dan aksi edit/hapus. Tampilkan progres
misalnya `2 dari 4 selesai`. Jangan membuat teks selesai sulit dibaca.

### Priority/category badges

Chip konsisten dan ringkas. Selalu sertakan label teks; jangan hanya
memakai warna.

### Reminder controls

Toggle Telegram, pilihan waktu, frekuensi, dan penjelasan bila Telegram
belum terhubung. Status jadwal menunggu sinkronisasi harus berbeda dari
status sudah dijadwalkan server.

### Analytics cards/charts

Angka dan label yang jelas, periode data terlihat, legenda mudah dibaca,
serta ringkasan teks yang tidak bergantung pada warna. Untuk Weekly Review,
gunakan kartu ringkasan tugas selesai, tugas tertunda, dan progres; hindari
peringkat, skor menghakimi, atau bahasa yang membuat pengguna merasa gagal.

### Sync status

State: Sinkron, Offline, Menunggu sinkronisasi, Menyinkronkan, Gagal,
Konflik. Sertakan waktu sinkronisasi terakhir bila tersedia.

### Telegram panel

State koneksi, tombol pesan uji, preferensi Morning Briefing dan
Weekly Review, zona waktu, serta status pengingat. Gunakan toggle dan
ringkasan jadwal yang mudah dipahami. Token bot tidak pernah ditampilkan
atau diminta di aplikasi publik.

### Notification log

Tampilkan judul tugas, waktu terjadwal, waktu kirim, kanal, dan status
eksplisit. Retry hanya untuk kondisi yang mendukung dan harus aman dari
duplikasi.

### Backup/export

Dialog pilihan format dan cakupan, progress, hasil, serta konfirmasi
sebelum restore/overwrite. Jangan memasukkan token atau secret ke
ekspor.

### Empty/loading/error/success

Gunakan skeleton untuk loading, CTA untuk empty state, pesan error yang
dapat ditindaklanjuti, dan feedback sukses hanya setelah operasi
dikonfirmasi.

## 9. Layout responsif

-   Mobile: satu kolom, navigasi bawah, form satu kolom, daftar agenda,
    kontrol sentuh besar.
-   Tablet: grid dua kolom untuk statistik dan layout adaptif.
-   Layar besar: navigasi samping bila sesuai, konten dengan lebar baca
    nyaman.
-   Widget Android: varian ringkas dan sedang jika didukung platform;
    hindari konten sensitif di layar terkunci.

## 10. Motion

Animasi kecil 150--220 ms untuk transisi dan feedback. Aksen komik lebih
aktif pada onboarding/empty state, tidak terus bergerak. Hormati reduced
motion dan jangan menghalangi penyelesaian tugas.

## 11. Aksesibilitas

Kontras yang memadai, fokus keyboard terlihat, label eksplisit, target
sentuh besar, dukungan pembaca layar, dan status tidak hanya
mengandalkan warna. Periksa juga skala font sistem dan tampilan pada
layar kecil.
