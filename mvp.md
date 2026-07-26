# Waleta PFM - Minimum Viable Product (MVP) Plan

Waleta adalah aplikasi Personal Financial Management (PFM) berbasis sistem amplop (Envelope System) yang dirancang secara khusus untuk mengatasi masalah pengelolaan keuangan sehari-hari, *impulse buying*, alokasi dana secara offline-first, serta kemudahan input data.

## 🎯 Visi & Tujuan MVP
Menyediakan pengalaman pengelolaan keuangan yang sangat cepat (tanpa delay *loading* berkat arsitektur *Offline-First*), mudah digunakan, dan secara aktif membatasi pengeluaran pengguna melalui konsep *Safe-to-Spend* (batas aman pengeluaran harian), serta didukung oleh fitur input pintar.

---

## 📦 Fitur Inti MVP (Saat ini sudah berjalan)

### 1. Offline-First Architecture & Sync
- **Local Storage**: Data utama (Akun, Dompet, Transaksi) disimpan secara lokal di memori HP. Pengguna bisa mencatat kapan saja tanpa perlu internet.
- **The Great Data Merge**: Sinkronisasi awal cerdas yang menggabungkan data offline ke dalam Cloud saat pengguna berhasil login/mendaftar dengan pencocokan nama amplop untuk mencegah duplikasi.
- **Cloud Backup**: Data di *backend* (VPS + PostgreSQL) bertindak sebagai *source of truth* sekunder untuk mencegah kehilangan data.

### 2. Envelope System (Sistem Amplop / Dompet Virtual)
- **Dompet Utama**: Pembagian dana ke Kebutuhan (50%), Keinginan (30%), dan Tabungan (20%) mengikuti prinsip 50/30/20.
- **Alokasi Dana (Allocate Funds)**: Fitur pembagian persentase dana atau nominal secara mudah dari total saldo rekening ke masing-masing dompet.
- **Safe-to-Spend (StS) Engine**:
  - *Kebutuhan*: Batas pengeluaran harian proporsional berdasarkan sisa hari dalam sebulan (Harian).
  - *Keinginan*: Dana bebas yang tidak dipatok per hari (Lump Sum).
  - *Tabungan*: Dana yang dikunci (locked) dan tidak dapat digunakan untuk transaksi harian.
  - *Emergency Runway*: Kalkulator otomatis pada dompet Tabungan untuk menghitung estimasi ketahanan hidup (dalam bulan) jika pendapatan terhenti.
- **Sub-kategori (Saku/Pocket)**: Membuat saku khusus (seperti bensin, skincare, dll.) di dalam dompet utama dengan warna, ikon, dan aturan STS terpisah.

### 3. Pencatatan Transaksi & Manajemen Aktivitas
- **Pemasukan (Income)**: Menambah total *pool* uang yang nantinya siap dialokasikan.
- **Pengeluaran (Expense)**: Memotong uang secara riil dari akun, sekaligus memotong dari alokasi dompet virtual.
- **Transfer**: Memindahkan uang antar rekening internal tanpa mempengaruhi alokasi anggaran dompet.
- **Mulai Lembaran Baru (Fresh Start)**: Fitur psikologis untuk mereset seluruh saldo menjadi nol (0) jika keuangan pengguna sudah terlalu kacau dan ingin mulai dari awal tanpa menghapus riwayat transaksi.
- **Multi-select & Edit**: Long-press riwayat untuk hapus massal, dan tap untuk edit detail secara instan via bottom sheet.

### 4. Smart Input & Asisten Cerdas (Fitur Unggulan)
- **OCR Scan Struk (Receipt Scanner)**: 
  - Mengambil foto struk belanja dengan kamera secara langsung (didukung toggle flash) atau mengunggah dari galeri.
  - Ekstraksi nominal total belanja, nama merchant, tanggal, serta detail item secara instan tanpa internet menggunakan **Google ML Kit Text Recognition** (on-device).
- **Kalkulator Internal**: Kalkulator built-in responsif dengan haptic feedback untuk mempermudah perhitungan nominal langsung saat mencatat transaksi tanpa perlu keluar aplikasi.
- **Inbox Transaksi (Assign Pocket)**: Transaksi tak berkategori masuk ke kotak masuk untuk di-assign secara pintar ke saku yang sesuai di kemudian hari dengan info STS real-time.

### 5. Laporan & Refleksi Finansial
- **Jurnal Refleksi**: Area khusus untuk menulis refleksi keuangan bulanan/tahunan sebagai bentuk kesadaran finansial.
- **Sunburst Chart**: Diagram lingkaran bersarang interaktif di bagian Jurnal untuk melihat persentase detail pengeluaran per kategori.
- **Penyesuaian Saldo (Rekonsiliasi)**: Pengguna dapat menyelaraskan saldo fisik dengan saldo aplikasi secara manual, dan sistem otomatis membuat transaksi koreksi.
- **Smart Privacy Blur**: Mode privasi (ikon mata) untuk menyembunyikan nominal saldo dari intipan orang di sebelah.

---

## 🚀 Rencana Fase Selanjutnya (Post-MVP / Phase 2)

Setelah MVP stabil dan dapat digunakan secara harian, pengembangan akan berfokus pada otomatisasi lanjutan:

### 1. Auto-Categorization & Sweeping Rules
- Otomatisasi pengkategorian transaksi yang sering berulang berdasarkan histori OCR/Merchant.
- **Income Sweeping**: Aturan yang bisa diset pengguna, misalnya "Jika ada pemasukan dari PT X, otomatis potong 10% langsung ke Tabungan".

### 2. Push Notification & Reminder
- Notifikasi pengingat harian untuk mencatat transaksi malam hari.
- Ringkasan batas aman Safe-to-Spend di pagi hari untuk panduan belanja.

### 3. Ekspor Laporan & Multi-User
- Ekspor data transaksi bulanan ke dalam format PDF/Excel.
- Fitur berbagi anggaran (shared budgeting) untuk kebutuhan keluarga atau pasangan.

---

## 🛠 Teknologi Pendukung
- **Frontend**: Flutter, Riverpod (State Management), GoRouter, SharedPreferences (Local Storage), FL Chart (Visualisasi).
- **Backend**: Golang, Fiber Framework, PostgreSQL, GORM.
- **Deployment**: Docker, Docker Compose, Python Deployment Script.

---

**Status Proyek**: MVP Core (Phase 1) telah selesai dengan optimasi visual minimalis-elegan dan perbaikan bug sinkronisasi multi-user. Siap untuk pengujian pengguna awal.
