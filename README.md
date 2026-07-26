<div align="center">

<img src="fe/assets/images/logo-with-titlepng.png" alt="Waleta Logo" width="300"/>

# Waleta — Aplikasi Manajemen Keuangan Personal

**Kendali penuh atas uangmu. Kapan saja, di mana saja.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Go](https://img.shields.io/badge/Go-1.22-00ADD8?logo=go)](https://go.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql)](https://www.postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://www.docker.com)

</div>

---

## 📋 Product Requirements Document (PRD)

### 1. Latar Belakang & Visi Produk

**Waleta** adalah aplikasi manajemen keuangan personal berbasis mobile yang dirancang untuk membantu pengguna Indonesia mengelola keuangan mereka dengan metode *envelope budgeting*. Berbeda dari aplikasi pencatatan keuangan biasa, Waleta mengintegrasikan tiga pilar utama: **pencatatan cerdas** (termasuk scan struk via OCR), **perencanaan anggaran dengan amplop digital**, dan **refleksi finansial** berbasis jurnal.

**Visi:** *"Menjadi teman finansial terpercaya bagi setiap orang Indonesia."*

**Masalah yang Diselesaikan:**
- Banyak orang tidak tahu ke mana uang mereka pergi setiap bulan
- Pencatatan manual terlalu melelahkan dan tidak konsisten
- Tidak ada sistem yang memaksa disiplin anggaran secara real-time
- Tidak ada ruang untuk refleksi atas keputusan finansial

---

### 2. Target Pengguna

| Segmen | Deskripsi |
|--------|-----------|
| **Primary** | Profesional muda (22–35 tahun) yang mulai sadar finansial |
| **Secondary** | Mahasiswa yang perlu mengelola uang bulanan dengan ketat |
| **Tertiary** | Keluarga muda yang ingin merencanakan anggaran rumah tangga |

---

### 3. Fitur Lengkap (Feature Set)

#### 🏠 Dashboard
- Ringkasan **total saldo real-time** dari seluruh akun/rekening yang terhubung
- **3 statistik utama** dalam satu pandang: Pengeluaran Bulan Ini, Pemasukan, dan Total Saldo
- **Filter bulan** — navigasi antar bulan/tahun langsung dari header
- **Privacy Mode** — tap ikon mata untuk sembunyikan semua angka sekaligus
- Daftar **riwayat transaksi** dikelompokkan per hari
- **Tap** pada transaksi → Edit langsung via bottom sheet
- **Long-press** transaksi → Mode multi-select untuk hapus massal
- **Pull-to-refresh** untuk sinkronisasi data terbaru dari server

#### 💳 Manajemen Akun (Rekening)
- Tambah beragam jenis akun: Bank, E-Wallet, Tunai, dan lainnya
- Tampilan **total saldo gabungan** dengan **diagram donat** (donut chart) per akun
- **Fitur Rekonsiliasi Saldo:** Pengguna memasukkan saldo aktual yang ada di rekening; sistem otomatis membuat transaksi koreksi penyesuaian sehingga catatan selalu akurat
- Edit nama & detail akun kapan saja
- Hapus akun beserta seluruh transaksinya

#### 📦 Envelope Budgeting (Inti Produk)
- Sistem **3 Master Envelope** bawaan: **Kebutuhan**, **Keinginan**, dan **Tabungan** (mengikuti prinsip 50/30/20)
- **Alokasi Dana dengan mode persentase atau nominal:**
  - Input nominal langsung (Rp) untuk masing-masing dompet
  - Toggle ke mode **persentase** — cukup isi "50%", sistem menghitung otomatis
  - Validasi real-time: total alokasi tidak boleh melebihi saldo yang tersedia
- **Sub-kategori (Saku/Pocket)** di dalam setiap envelope:
  - Buat saku spesifik (mis: "Bensin", "Skincare", "Netflix")
  - Setiap saku punya ikon & warna unik
  - Saku memiliki **Aturan Safe-to-Spend (STS)** tersendiri
- **Mode Safe-to-Spend (STS)** per saku:
  - **Harian** — saldo dibagi rata ke hari tersisa di bulan ini
  - **Bebas (Lump Sum)** — seluruh saldo bebas dipakai kapan saja
  - **Custom Periode** — saldo dibagi ke jumlah hari yang ditentukan sendiri
  - **Terkunci** — untuk tabungan, tidak masuk hitungan STS
- **Emergency Runway** — khusus di dompet Tabungan, sistem menghitung *berapa bulan kamu bisa bertahan* jika kehilangan pendapatan, berdasarkan rata-rata pengeluaran kebutuhanmu
- **Rollover** — sisa saldo dompet otomatis dipindahkan ke bulan berikutnya
- **Hapus saku** — sisa saldo otomatis kembali ke dana "Belum Dialokasikan"

#### 📷 OCR Scan Struk (Fitur Unggulan)
- Buka kamera langsung dari tombol tambah transaksi
- **Scan struk belanja** fisik atau digital (dari galeri foto)
- **Toggle flash** untuk kondisi cahaya rendah
- Sistem OCR berbasis **Google ML Kit Text Recognition** memproses gambar secara on-device (tanpa perlu koneksi internet)
- Ekstraksi otomatis:
  - **Total belanja** (mendeteksi berbagai format: "TOTAL", "GRAND TOTAL", "JUMLAH", dll.)
  - **Nama merchant/toko** dari baris teratas struk
  - **Tanggal transaksi** (mendukung berbagai format tanggal Indonesia)
  - **Daftar item belanjaan** beserta harga masing-masing
- Hasil scan langsung **mengisi form transaksi** — pengguna tinggal konfirmasi dan simpan
- Mendukung upload dari **galeri foto** sebagai alternatif kamera langsung

#### 🧮 Kalkulator Terintegrasi
- Kalkulator **built-in** yang dapat diakses langsung dari layar pencatatan transaksi
- Operasi dasar: tambah, kurang, kali, bagi
- **Haptic feedback** pada setiap tombol untuk pengalaman yang responsif
- **Salin hasil** — tombol copy untuk tempel ke field nominal transaksi
- Tampilan ekspresi dan hasil secara terpisah untuk keterbacaan lebih baik
- Mendukung desimal

#### 💸 Pencatatan Transaksi
- **Bottom sheet** 3-tab: **Pengeluaran**, **Pemasukan**, **Transfer**
- **Tab Pengeluaran:**
  - Input nominal + keterangan
  - Pilih sumber akun (bank atau tunai)
  - Pilih envelope/dompet tujuan
  - Pilih tanggal (default: hari ini)
  - Catatan tambahan opsional
- **Tab Pemasukan:**
  - Input nominal + kategori (Gaji, Bonus, Investasi, dll.)
  - Pilih rekening tujuan
- **Tab Transfer:**
  - Transfer antar rekening internal
  - Validasi saldo mencukupi sebelum simpan
- **Quick-assign dari inbox** — transaksi yang belum dikategorikan dapat di-assign ke saku belakangan via lembar `AssignPocketSheet` yang menampilkan STS real-time setiap pilihan

#### 📊 Statistik & Analitik
- **Tab Pengeluaran per Kategori:**
  - Grafik **donut chart** interaktif dengan legenda
  - Breakdown pengeluaran per envelope/saku untuk bulan yang dipilih
  - **Daftar merchant teratas** (top spending destinations)
- **Tab Tren Bulanan:**
  - Grafik **bar chart** perbandingan pemasukan vs pengeluaran 6 bulan terakhir
  - Visualisasi tren keuangan untuk identifikasi pola
- Navigasi antar bulan langsung dari layar statistik

#### 📓 Jurnal Finansial
- Fitur **jurnal refleksi** bulanan dan tahunan — ruang untuk mencatat perasaan dan evaluasi atas kondisi finansial
- **Tab Bulanan:** pilih bulan & tahun, tulis catatan bebas, simpan otomatis ke perangkat
- **Tab Tahunan:** refleksi atas setahun penuh
- **Evaluasi "Menyesal?"** per transaksi pengeluaran — tandai apakah sebuah pengeluaran terasa sia-sia atau bermanfaat, untuk pembelajaran ke depan
- **Sunburst Chart** visual pengeluaran per kategori (nested pie chart)
- Semua data jurnal disimpan lokal di perangkat (SharedPreferences) — privat dan offline

#### ⚙️ Pengaturan & Privasi
- **Mulai Lembaran Baru (Fresh Start):** Reset semua data transaksi historis tanpa menghapus akun dan dompet — solusi ideal bagi pengguna yang ingin memulai pelacakan dari awal
- Profil pengguna (nama, email)
- Pilihan tema aplikasi (Light / Dark)

#### 🔐 Autentikasi & Keamanan
- Register & Login dengan email/password
- **JWT-based session management** — token tersimpan aman di perangkat
- **Biometric authentication** (fingerprint / face ID) via `local_auth` — login cepat tanpa ketik password
- Data sinkronisasi ke server VPS yang dikelola sendiri

---

### 4. Arsitektur Teknis

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT (Mobile App)                     │
│                                                             │
│   Flutter 3.x  ·  Riverpod (State Mgmt)  ·  GoRouter       │
│   Google Fonts (Plus Jakarta Sans)  ·  FL Chart             │
│   ML Kit OCR  ·  Local Auth  ·  SharedPreferences           │
│   flutter_animate  ·  skeletonizer  ·  lucide_icons         │
└─────────────────────────┬───────────────────────────────────┘
                          │  HTTP/REST (JSON)
                          │  http://76.13.17.86:3000/api/v1
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   SERVER (VPS: 76.13.17.86)                 │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │          Go + Fiber Framework (Port 3000)           │   │
│   │                                                     │   │
│   │  Handlers → Services → Repository → GORM           │   │
│   │  JWT Middleware  ·  CORS  ·  Rate Limiting          │   │
│   └───────────────────────┬─────────────────────────────┘   │
│                           │                                 │
│   ┌───────────────────────▼─────────────────────────────┐   │
│   │           PostgreSQL 15 (Docker Container)          │   │
│   │                                                     │   │
│   │  users · accounts · envelopes · pockets             │   │
│   │  transactions · master_envelopes · sources          │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│                   Managed via Docker Compose                │
└─────────────────────────────────────────────────────────────┘
```

#### Stack Teknologi

| Layer | Teknologi |
|-------|-----------|
| **Mobile** | Flutter 3.x (Dart) |
| **State Management** | Riverpod (Notifier pattern) |
| **Routing** | GoRouter |
| **Backend** | Go 1.22 + Fiber v2 |
| **ORM** | GORM |
| **Database** | PostgreSQL 15 |
| **Autentikasi** | JWT (golang-jwt/jwt v5) + Biometric (local_auth) |
| **OCR Engine** | Google ML Kit Text Recognition (on-device) |
| **Animasi** | flutter_animate |
| **Charts** | FL Chart + custom Sunburst Chart |
| **Deployment** | Docker Compose di VPS |
| **CI/CD** | GitHub |

---

### 5. Struktur Direktori

```
waleta/
├── fe/                          # Flutter Frontend
│   ├── lib/
│   │   ├── core/
│   │   │   ├── api/             # ApiClient & ApiEndpoints
│   │   │   ├── routes/          # GoRouter configuration
│   │   │   ├── theme/           # Warna (AppColors), tipografi, tema
│   │   │   └── storage/         # SharedPreferences & LocalStorageService
│   │   ├── features/
│   │   │   ├── auth/            # Login & Register
│   │   │   ├── dashboard/       # Home screen, providers, rollover
│   │   │   ├── accounts/        # Rekening, rekonsiliasi saldo
│   │   │   ├── envelopes/       # Envelope & Pocket budgeting, alokasi
│   │   │   ├── activity/        # Transaksi, OCR scanner, kalkulator
│   │   │   │   ├── screens/
│   │   │   │   │   ├── activity_screen.dart
│   │   │   │   │   ├── camera_scanner_screen.dart  # OCR
│   │   │   │   │   └── calculator_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── quick_add_transaction_sheet.dart
│   │   │   │       ├── calculator_sheet.dart       # Kalkulator
│   │   │   │       └── assign_pocket_sheet.dart    # STS-aware assign
│   │   │   ├── journal/         # Jurnal refleksi + sunburst chart
│   │   │   ├── statistics/      # Grafik, donut chart, tren bulanan
│   │   │   ├── profile/         # Profil pengguna
│   │   │   └── settings/        # Pengaturan & Fresh Start
│   │   ├── services/
│   │   │   └── ocr_service.dart # ML Kit OCR + parsing struk
│   │   ├── models/
│   │   │   └── ocr_result.dart  # Model hasil scan
│   │   └── main.dart
│   ├── android/
│   └── ios/
│
├── be/                          # Go Backend
│   ├── cmd/api/main.go          # Entry point
│   ├── internal/
│   │   ├── config/              # Database connection
│   │   ├── handlers/            # HTTP request handlers
│   │   ├── middleware/          # Auth JWT middleware
│   │   ├── models/              # GORM data models
│   │   ├── repository/          # Database queries
│   │   └── service/             # Business logic
│   ├── db/migrations/           # SQL migration files
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── deploy.py                    # Script deploy otomatis ke VPS (via Paramiko SSH)
└── README.md
```

---

### 6. API Endpoints

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| `POST` | `/api/v1/auth/register` | Daftar akun baru |
| `POST` | `/api/v1/auth/login` | Login & dapatkan JWT |
| `GET` | `/api/v1/auth/me` | Info user yang login |
| `GET/POST` | `/api/v1/accounts` | Daftar & buat akun |
| `PUT/DELETE` | `/api/v1/accounts/:id` | Edit / hapus akun |
| `POST` | `/api/v1/accounts/:id/reconcile` | Sesuaikan saldo akun |
| `POST` | `/api/v1/accounts/fresh-start` | Mulai lembaran baru |
| `GET/POST` | `/api/v1/envelopes` | Daftar & buat envelope |
| `POST` | `/api/v1/envelopes/allocate` | Alokasikan dana ke envelope |
| `GET/POST` | `/api/v1/pockets` | Daftar & buat saku |
| `PUT/DELETE` | `/api/v1/pockets/:id` | Edit / hapus saku |
| `POST` | `/api/v1/transactions/income` | Catat pemasukan |
| `POST` | `/api/v1/transactions/expense` | Catat pengeluaran |
| `POST` | `/api/v1/transactions/transfer` | Transfer antar rekening |
| `PUT/DELETE` | `/api/v1/transactions/:id` | Edit / hapus transaksi |
| `DELETE` | `/api/v1/transactions/bulk` | Hapus massal transaksi |
| `GET` | `/api/v1/dashboard/summary` | Ringkasan dashboard |
| `GET` | `/api/v1/journal/monthly/:year/:month` | Laporan bulanan |
| `POST` | `/api/v1/sync` | Sinkronisasi data offline |

---

### 7. Cara Menjalankan Lokal

#### Backend (Go)

```bash
cd be/

# Copy environment variables
cp .env.example .env
# Edit .env sesuai konfigurasi database lokal

# Jalankan dengan Docker Compose
docker compose up -d --build

# Atau jalankan langsung
go run ./cmd/api/main.go
```

#### Frontend (Flutter)

```bash
cd fe/

# Install dependencies
flutter pub get

# Ubah baseUrl di lib/core/api/api_endpoints.dart
# Untuk emulator Android: http://10.0.2.2:3000/api/v1
# Untuk VPS:             http://76.13.17.86:3000/api/v1

# Jalankan di device/emulator
flutter run

# Build APK release
flutter build apk --release
# Hasil: build/app/outputs/flutter-apk/app-release.apk
```

#### Deploy ke VPS

```bash
# Pastikan Python & paramiko terinstall
pip install paramiko scp

# Jalankan script deploy otomatis (SSH ke VPS, pull, rebuild, restart)
python deploy.py
```

---

### 8. Environment Variables (Backend)

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=waleta_user
DB_PASSWORD=waleta_password
DB_NAME=waleta_db
DB_SSLMODE=disable
JWT_SECRET=your_jwt_secret_here
```

---

### 9. Roadmap

#### Near-term
- [ ] Push Notification harian — pengingat catat transaksi & ringkasan STS pagi hari
- [ ] Widget di home screen Android/iOS
- [ ] Ekspor laporan ke PDF/Excel
- [ ] Dark mode toggle yang dapat diatur pengguna

#### Mid-term
- [ ] **Integrasi mutasi rekening otomatis** (Open Banking API / notifikasi SMS parser)
- [ ] Multi-currency support
- [ ] Fitur berbagi anggaran (untuk pasangan/keluarga)
- [ ] Repeat/template transaksi rutin (mis: bayar cicilan otomatis)

#### Long-term
- [ ] AI Insight — analisis pola pengeluaran dan rekomendasi anggaran berbasis data pribadi
- [ ] Gamifikasi — badge dan streak untuk memotivasi konsistensi pencatatan
- [ ] Integrasi investasi (reksa dana, saham)

---

### 10. Kontribusi

Pull request sangat diterima! Untuk perubahan besar, mohon buka issue terlebih dahulu untuk mendiskusikan apa yang ingin diubah.

---

<div align="center">

Dibuat dengan ❤️ menggunakan Flutter & Go

</div>
