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

**Waleta** adalah aplikasi manajemen keuangan personal berbasis mobile yang dirancang untuk membantu pengguna Indonesia mengelola keuangan mereka dengan metode *envelope budgeting*. Aplikasi ini memungkinkan pengguna untuk:

- Melacak pemasukan dan pengeluaran secara real-time
- Mengalokasikan uang ke "amplop" (kategori) anggaran
- Mendapatkan gambaran lengkap kondisi finansial pribadi
- Menyesuaikan saldo secara manual jika terdapat selisih

**Visi:** *"Menjadi teman finansial terpercaya bagi setiap orang Indonesia."*

---

### 2. Target Pengguna

| Segmen | Deskripsi |
|--------|-----------|
| **Primary** | Profesional muda (22–35 tahun) yang mulai sadar finansial |
| **Secondary** | Mahasiswa yang perlu mengelola uang bulanan dengan ketat |
| **Tertiary** | Keluarga muda yang ingin merencanakan anggaran rumah tangga |

---

### 3. Fitur Utama (Feature Set)

#### 🏠 Dashboard
- Ringkasan total saldo seluruh akun/rekening
- Widget *Net Unallocated* — menampilkan uang yang belum dialokasikan secara akurat (memperhitungkan saldo minus)
- Daftar aktivitas transaksi terbaru
- Tap transaksi → Edit langsung via bottom sheet
- Long-press transaksi → Mode multi-select untuk hapus massal

#### 💳 Manajemen Akun (Rekening)
- Tambah akun baru (Bank, E-Wallet, Tunai, dll.)
- **Fitur Sesuaikan Saldo (Rekonsiliasi Manual):** Pengguna memasukkan saldo aktual; sistem otomatis membuat transaksi koreksi
- Tampilan total saldo gabungan dengan diagram donat (*donut chart*) per akun

#### 📦 Envelope Budgeting
- Buat dan kelola *master envelope* (mis: Makan, Transport, Hiburan)
- Buat sub-kategori (pocket) di dalam setiap envelope
- Alokasikan uang dari saldo "belum dialokasikan" ke envelope
- Rollover sisa anggaran ke bulan berikutnya

#### 💸 Transaksi
- Catat pengeluaran dengan pilihan sumber akun dan envelope tujuan
- Catat pemasukan langsung ke akun tertentu
- **OCR Struk:** Scan struk belanja menggunakan kamera untuk input otomatis (powered by Google ML Kit)
- Inbox transaksi — transaksi yang belum dikategorikan dapat di-assign belakangan

#### 📊 Jurnal & Statistik
- Laporan bulanan: Ringkasan pemasukan vs pengeluaran per bulan
- Laporan tahunan: Tren keuangan sepanjang tahun
- Diagram *donut chart* per kategori pengeluaran
- Visualisasi arus kas (*cashflow*)

#### ⚙️ Pengaturan
- **Mulai Lembaran Baru (Fresh Start):** Reset semua data transaksi historis tanpa menghapus akun — solusi ideal bagi pengguna yang ingin memulai ulang
- Profil pengguna (nama, email)
- Tema aplikasi

#### 🔐 Autentikasi
- Register & Login dengan email/password
- JWT-based session management
- Biometric authentication (fingerprint/face ID)

---

### 4. Arsitektur Teknis

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT (Mobile App)                     │
│                                                             │
│   Flutter 3.x  ·  Riverpod (State Mgmt)  ·  GoRouter       │
│   Google Fonts  ·  FL Chart  ·  ML Kit OCR  ·  Local Auth  │
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
│   │  transactions · notifications · rules               │   │
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
| **Autentikasi** | JWT (golang-jwt/jwt v5) |
| **Deployment** | Docker Compose di VPS |
| **OCR** | Google ML Kit Text Recognition |
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
│   │   │   ├── theme/           # Warna, tipografi, tema
│   │   │   └── storage/         # SharedPreferences service
│   │   ├── features/
│   │   │   ├── auth/            # Login & Register
│   │   │   ├── dashboard/       # Home screen & providers
│   │   │   ├── accounts/        # Rekening & Rekonsiliasi
│   │   │   ├── envelopes/       # Envelope & Pocket budgeting
│   │   │   ├── activity/        # Transaksi & OCR scanner
│   │   │   ├── journal/         # Laporan bulanan/tahunan
│   │   │   ├── statistics/      # Grafik & chart
│   │   │   └── settings/        # Pengaturan & Fresh Start
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
├── deploy.py                    # Script deploy otomatis ke VPS
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
| `POST` | `/api/v1/accounts/:id/reconcile` | Sesuaikan saldo akun |
| `POST` | `/api/v1/accounts/fresh-start` | Mulai lembaran baru |
| `GET/POST` | `/api/v1/envelopes` | Daftar & buat envelope |
| `POST` | `/api/v1/envelopes/allocate` | Alokasikan dana ke envelope |
| `POST` | `/api/v1/transactions/income` | Catat pemasukan |
| `POST` | `/api/v1/transactions/expense` | Catat pengeluaran |
| `GET` | `/api/v1/dashboard/summary` | Ringkasan dashboard |
| `GET` | `/api/v1/journal/monthly/:year/:month` | Laporan bulanan |

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

# Jalankan script deploy otomatis
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

- [ ] Push Notification (Firebase FCM)
- [ ] Ekspor laporan ke PDF/Excel
- [ ] Multi-currency support
- [ ] Fitur berbagi anggaran (untuk pasangan/keluarga)
- [ ] Widget di home screen Android/iOS
- [ ] Dark mode yang dapat diatur pengguna
- [ ] Integrasi mutasi rekening otomatis (Open Banking API)

---

### 10. Kontribusi

Pull request sangat diterima! Untuk perubahan besar, mohon buka issue terlebih dahulu untuk mendiskusikan apa yang ingin diubah.

---

<div align="center">

Dibuat dengan ❤️ menggunakan Flutter & Go

</div>
