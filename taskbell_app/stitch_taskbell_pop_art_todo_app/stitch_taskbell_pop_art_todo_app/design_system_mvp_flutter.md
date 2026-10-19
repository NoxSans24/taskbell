# Design System --- TaskBell Android (MVP & Flutter Ready)

## 1. Prinsip Visual Komik / Pop-Art
TaskBell mempertahankan identitas kuat comic-book/pop-art:
- **Latar Belakang**: Krem hangat `#FFF9EC` (surface `#FFFFFF`).
- **Outline & Border**: Hitam tegas 2px solid `#171717`.
- **Hard Shadow (Bayangan Keras Komik)**: `BoxShadow(offset: Offset(3, 3), blurRadius: 0, color: Color(0xFF171717))`.
- **Aksen Warna Utama**:
  - Biru Pop Primary: `#347BE5` (CTA, fokus, tombol utama)
  - Kuning Secondary: `#FFB900` (Highlight, kartu terpilih, aksen)
  - Oranye Energetik: `#FF8A00` (Status sedang, perhatian)
  - Merah Peringatan / Destruktif: `#E91E4B` (Tugas terlambat, hapus, logout)
  - Hijau Sukses: `#197447` (Terselesaikan, koneksi aktif)
  - Teks Utama: `#171717` | Teks Redup: `#555555`

---

## 2. Aturan SVG-Only Wajib (Flutter Implementation)
- **Tanpa Emoji & Icon Fonts**: Seluruh elemen antarmuka, chip, status, indikator, dan kontrol tombol wajib menggunakan SVG inline atau aset vector XML/SVG lokal.
- **Konsistensi Visual Ikon**:
  - `stroke-width`: 2px atau 2.5px tegas, sejalan dengan garis batas komik.
  - `stroke-linecap="round"` & `stroke-linejoin="round"`.
  - Ukuran standar: 16px (chip/badge), 20px (input/list icon), 24px (navigasi & header).
- **Aksesibilitas Ikon**:
  - Setiap tombol ikon wajib memiliki atribut `aria-label` / `semanticsLabel`.
  - Status penting (Tersinkron, Terlambat, Sukses, Error) wajib menampilkan ikon SVG berdampingan dengan label teks deskriptif.

---

## 3. Komponen Siap Flutter

### A. Tombol Komik (Comic Button)
- Tinggi minimum: 48px, target sentuh aman ≥ 48×48 px.
- Varian: Primary (`#347BE5`), Secondary (`#FFFFFF` border hitam), Accent Yellow (`#FFB900`), Destructive (`#E91E4B`).
- State: Default, Pressed (geser offset `1px 1px`), Disabled (warna abu-abu `#E0E0E0` dengan border `#888888`), Loading (animasi spinner SVG).

### B. Input Field Komik (Comic Input)
- Outline 2px `#171717`, background `#FFFFFF`, radius 8px-12px.
- Ikon SVG di awal (*prefix*) dan aksi di akhir (*suffix*, misal toggle mata intip sandi).
- Teks error merah `#E91E4B` muncul tepat di bawah field jika validasi gagal.

### C. Kartu Tugas (Task Card MVP)
- Border hitam 2px, radius 12px, bayangan keras komik.
- Menampilkan: Checkbox SVG bulat/kotak, Judul, Chip Kategori, Badge Prioritas, Ikon jam & Tenggat Waktu, Aksi cepat.
- Tidak menampilkan subtasks bertingkat atau label teknis DB pada versi MVP.

### D. Penanganan State Interaktif
- **Empty State**: Kotak komik dengan ilustrasi garis SVG ramah, speech bubble motivasi, dan tombol aksi pemulihan/tambah.
- **Offline / Sync State**: Banner peringatan informatif ramah tanpa membingungkan pengguna awam.
