# Waleta PFM - Minimum Viable Product (MVP) Plan

Waleta adalah aplikasi Personal Financial Management (PFM) berbasis sistem amplop (Envelope System) yang dirancang secara khusus untuk mengatasi masalah pengelolaan keuangan sehari-hari, *impulse buying*, dan alokasi dana secara offline-first.

## 🎯 Visi & Tujuan MVP
Menyediakan pengalaman pengelolaan keuangan yang sangat cepat (tanpa delay *loading* berkat arsitektur *Offline-First*), mudah digunakan, dan secara aktif membatasi pengeluaran pengguna melalui konsep *Safe-to-Spend* (batas aman pengeluaran harian).

---

## 📦 Fitur Inti MVP (Saat ini sudah berjalan)

### 1. Offline-First Architecture & Sync
- **Local Storage**: Data utama (Akun, Dompet, Transaksi) disimpan secara lokal di memori HP. Pengguna bisa mencatat kapan saja tanpa perlu internet.
- **The Great Data Merge**: Sinkronisasi awal cerdas yang menggabungkan data offline ke dalam Cloud saat pengguna berhasil login/mendaftar.
- **Cloud Backup**: Data di *backend* (VPS + PostgreSQL) bertindak sebagai *source of truth* sekunder untuk mencegah kehilangan data.

### 2. Envelope System (Sistem Amplop / Dompet Virtual)
- **Dompet Utama**: Pembagian dana ke Kebutuhan (50%), Keinginan (30%), dan Tabungan (20%).
- **Alokasi Dana (Allocate Funds)**: Fitur pembagian persentase dana secara mudah dari total saldo rekening ke masing-masing dompet.
- **Safe-to-Spend (StS) Engine**:
  - *Kebutuhan*: Batas pengeluaran harian proporsional berdasarkan sisa hari dalam sebulan.
  - *Keinginan*: Dana bebas yang tidak dipatok per hari.
  - *Tabungan*: Dana yang dikunci (locked) dan tidak dapat digunakan untuk transaksi harian.

### 3. Pencatatan Transaksi (Activity)
- **Pemasukan (Income)**: Menambah total *pool* uang yang nantinya siap dialokasikan.
- **Pengeluaran (Expense)**: Memotong uang secara riil dari akun, sekaligus memotong dari alokasi dompet virtual.
- **Mulai Lembaran Baru (Fresh Start)**: Fitur psikologis untuk mereset seluruh saldo menjadi nol (0) jika keuangan pengguna sudah terlalu kacau dan ingin mulai dari awal tanpa menghapus riwayat transaksi.

### 4. Smart Input & UX
- **Kalkulator Internal**: Memudahkan perhitungan matematis langsung saat input nominal tanpa harus berpindah aplikasi.
- **Pull-to-Refresh**: Sinkronisasi paksa dan penyegaran data *dashboard*, transaksi, dan akun dalam satu tarikan.
- **Smart Privacy Blur**: Mode privasi (ikon mata) untuk menyembunyikan nominal saldo dari intipan orang di sebelah.

---

## 🚀 Rencana Fase Selanjutnya (Post-MVP / Phase 2)

Setelah MVP stabil dan dapat digunakan secara harian, pengembangan akan berfokus pada otomatisasi dan laporan analitik:

### 1. Smart OCR Receipt Scanner (Taraf Integrasi)
- Scan struk belanja secara langsung lewat kamera.
- Mengubah gambar struk menjadi baris-baris *items* transaksi.

### 2. Auto-Categorization & Sweeping Rules
- Otomatisasi pengkategorian transaksi yang sering berulang.
- **Income Sweeping**: Aturan yang bisa diset pengguna, misalnya "Jika ada pemasukan dari PT X, otomatis potong 10% langsung ke Tabungan".

### 3. Multi-Account Management & Transfer
- Mendukung berbagai jenis rekening secara spesifik (BCA, Mandiri, Gopay, OVO).
- Transaksi jenis **Transfer** antar akun tanpa mengubah total saldo keseluruhan.

### 4. Laporan & Jurnal Historis
- Laporan komprehensif pengeluaran bulan ini dibandingkan bulan lalu.
- Peringatan (*Frugality Warning*) jika pola pengeluaran untuk 'Keinginan' mulai berlebihan (Notifikasi).

---

## 🛠 Teknologi Pendukung
- **Frontend**: Flutter, Riverpod (State Management), GoRouter, Hive/Shared Preferences (Local Storage).
- **Backend**: Golang, Fiber Framework, PostgreSQL, GORM.
- **Deployment**: Docker, Docker Compose, Python Deployment Script.

---

**Status Proyek**: MVP Core (Phase 1) telah selesai dan masuk dalam tahap perbaikan *bug* akhir (*polishing*) sebelum *soft-launch* ke pengguna awal.
