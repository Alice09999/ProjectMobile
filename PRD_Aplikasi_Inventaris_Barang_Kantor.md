# PRD — Aplikasi Inventaris Barang Kantor

| | |
|---|---|
| **Mata Kuliah** | Pemrograman Berbasis Mobile |
| **Dosen** | Akhmad Jayadi, S.Kom., M.Cs. |
| **Program Studi** | D3 Manajemen Informatika, Jurusan Teknologi Informasi, Politeknik Negeri Lampung |
| **Tim** | Devnis Arga Vanis Setiawan, Fatir Kausar, M. Chaesar Abdullah, Nurul Aliya, Riani Azzahra Saridewi, Silvia Nanda Agustin |
| **Tahun** | 2025 |
| **Platform** | Mobile (Android/iOS) |
| **Stack** | Flutter + Dart, MySQL, Figma, GitHub, VS Code |
| **Status** | Draft v1.0 |

---

## 1. Ringkasan Produk

Aplikasi mobile untuk mengelola inventaris barang kantor secara digital. Aplikasi menggantikan pencatatan manual (buku besar/spreadsheet) dan mencakup pendataan barang, pengajuan peminjaman dan pengembalian, pemantauan kondisi barang, serta riwayat transaksi. Aplikasi dibangun dengan **Flutter (Dart)** dan menyimpan data di **MySQL**.

## 2. Latar Belakang & Masalah

Pengelolaan inventaris manual menimbulkan masalah berikut:

1. Data stok tidak akurat.
2. Sulit melacak barang yang sedang dipinjam karyawan.
3. Kondisi barang (baik/rusak) tidak diketahui secara real-time.
4. Risiko *human error* tinggi dan proses peminjaman/pengembalian lambat.

## 3. Tujuan & Indikator Keberhasilan

| Tujuan | Indikator |
|---|---|
| Mendata aset kantor secara digital | Seluruh barang tercatat dengan CRUD berfungsi |
| Mempermudah karyawan meminjam & mengembalikan barang | Pengajuan pinjam/kembali dapat dilakukan dari aplikasi |
| Membantu admin memantau kondisi & ketersediaan | Stok dan kondisi barang tampil akurat |
| Menyediakan riwayat transaksi terdokumentasi | Riwayat peminjaman dapat dilihat admin dan karyawan |

**Non-goals (di luar cakupan versi ini):** notifikasi push, scan barcode/QR, ekspor PDF/Excel, multi-kantor, registrasi mandiri.

## 4. Pengguna (Aktor)

| Aktor | Deskripsi | Kebutuhan Utama |
|---|---|---|
| **Admin** (Pengelola Barang) | Mengelola aset dan menyetujui peminjaman | Kelola barang, proses pengajuan, update kondisi, lihat laporan |
| **Karyawan** | Peminjam barang kantor | Lihat katalog, ajukan pinjam/kembali, lihat riwayat pribadi |

## 5. Kebutuhan Fungsional

### 5.1 Admin

| ID | Fitur | Deskripsi | Prioritas |
|---|---|---|---|
| A-01 | Login Admin | Autentikasi email + password, hanya role `Admin` | Must |
| A-02 | CRUD Barang | Tambah, lihat, ubah, hapus data barang | Must |
| A-03 | Manajemen Peminjaman | Lihat daftar pengajuan, setujui atau tolak | Must |
| A-04 | Update Kondisi Barang | Ubah status barang: Tersedia, Dipinjam, Rusak | Must |
| A-05 | Laporan | Lihat riwayat peminjaman dan pengembalian | Should |

### 5.2 Karyawan

| ID | Fitur | Deskripsi | Prioritas |
|---|---|---|---|
| K-01 | Login Karyawan | Autentikasi, hanya role `Karyawan` | Must |
| K-02 | Katalog Barang | Daftar barang tersedia beserta kondisi | Must |
| K-03 | Pengajuan Peminjaman | Form meminjam barang | Must |
| K-04 | Pengajuan Pengembalian | Ajukan pengembalian barang yang dipinjam | Must |
| K-05 | Riwayat | Lihat status pengajuan pribadi | Must |

### 5.3 Aturan Bisnis

- Barang dengan kondisi `Rusak` atau stok `0` tidak dapat dipinjam.
- Stok berkurang saat pengajuan disetujui dan bertambah saat pengembalian selesai.
- Karyawan hanya dapat melihat data peminjaman miliknya sendiri.
- Hanya Admin yang dapat mengubah data barang dan menyetujui/menolak pengajuan.
- Password disimpan terenkripsi (hash), tidak pernah ditampilkan.

## 6. Alur Utama (User Flow)

**Peminjaman:**
`Karyawan login → Katalog → pilih barang → isi form pinjam → status "Menunggu" → Admin setujui → status "Dipinjam" (stok berkurang)` → jika ditolak, pengajuan berakhir dan stok tidak berubah.

**Pengembalian:**
`Karyawan ajukan pengembalian → Admin konfirmasi & cek kondisi → status "Selesai" (stok bertambah, tanggal_kembali terisi, kondisi diperbarui bila rusak)`

## 7. Skema Database (MySQL)

### 7.1 Tabel `users`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id_user | INT | Primary Key |
| nama_lengkap | VARCHAR | Nama pengguna |
| email | VARCHAR | Email pengguna |
| password | VARCHAR | Password terenkripsi |
| role | ENUM('Admin','Karyawan') | Peran pengguna |

### 7.2 Tabel `barang`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id_barang | INT | Primary Key |
| nama_barang | VARCHAR | Nama barang |
| kategori | VARCHAR | Kategori barang |
| stok | INT | Jumlah barang tersedia |
| kondisi | ENUM('Baik','Rusak') | Kondisi barang |

### 7.3 Tabel `peminjaman`

| Kolom | Tipe | Keterangan |
|---|---|---|
| id_pinjam | INT | Primary Key |
| id_user | INT | FK → users |
| id_barang | INT | FK → barang |
| tanggal_pinjam | DATE | Tanggal mulai pinjam |
| tanggal_kembali | DATE | Tanggal dikembalikan |
| status | ENUM('Menunggu','Dipinjam','Selesai') | Status transaksi |

### 7.4 Catatan Ketidaksesuaian pada Skema (Rekomendasi)

Beberapa hal pada laporan perlu diselaraskan agar fitur dapat berjalan:

| Temuan | Rekomendasi |
|---|---|
| Fitur A-03 ada "menolak", tetapi status peminjaman hanya `Menunggu/Dipinjam/Selesai` | Tambah status `Ditolak` |
| Fitur A-04 menyebut status barang `Tersedia/Dipinjam/Rusak`, tetapi kolom `kondisi` hanya `Baik/Rusak` | Pertahankan `kondisi` (Baik/Rusak). Status "Tersedia/Dipinjam" diturunkan dari `stok` dan transaksi aktif, atau tambah kolom `status` |
| Pengajuan pengembalian (K-04) belum punya status | Tambah status `Menunggu Pengembalian` |
| Tidak ada jumlah barang yang dipinjam | Tambah kolom `jumlah INT` pada `peminjaman` |

DDL yang direkomendasikan (sudah mencakup rekomendasi di atas):

```sql
CREATE TABLE users (
  id_user INT AUTO_INCREMENT PRIMARY KEY,
  nama_lengkap VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role ENUM('Admin','Karyawan') NOT NULL
);

CREATE TABLE barang (
  id_barang INT AUTO_INCREMENT PRIMARY KEY,
  nama_barang VARCHAR(100) NOT NULL,
  kategori VARCHAR(50) NOT NULL,
  stok INT NOT NULL DEFAULT 0,
  kondisi ENUM('Baik','Rusak') NOT NULL DEFAULT 'Baik'
);

CREATE TABLE peminjaman (
  id_pinjam INT AUTO_INCREMENT PRIMARY KEY,
  id_user INT NOT NULL,
  id_barang INT NOT NULL,
  jumlah INT NOT NULL DEFAULT 1,
  tanggal_pinjam DATE NOT NULL,
  tanggal_kembali DATE NULL,
  status ENUM('Menunggu','Dipinjam','Menunggu Pengembalian','Selesai','Ditolak')
         NOT NULL DEFAULT 'Menunggu',
  FOREIGN KEY (id_user) REFERENCES users(id_user),
  FOREIGN KEY (id_barang) REFERENCES barang(id_barang)
);
```

## 8. Arsitektur Teknis (Flutter / Dart)

### 8.1 Gambaran Arsitektur

> Flutter tidak sebaiknya terhubung langsung ke MySQL (kredensial database akan terekspos di aplikasi). Laporan menyebut "integrasi database"; rekomendasinya adalah menambah **REST API** (misalnya PHP/Laravel atau Node.js) sebagai penghubung antara aplikasi Flutter dan MySQL. Pilihan backend ini adalah asumsi dan perlu disepakati tim.

```
Flutter App (Dart)  ──HTTP/JSON──▶  REST API  ──▶  MySQL
 UI → Provider → Repository → ApiService
```

### 8.2 Pola & Library

| Kebutuhan | Pilihan |
|---|---|
| Arsitektur | Layered: `presentation` / `providers` / `data` (model, repository, service) |
| State management | `provider` |
| HTTP client | `http` (atau `dio`) |
| Penyimpanan sesi/token | `shared_preferences` (atau `flutter_secure_storage`) |
| Navigasi | `go_router` (atau `Navigator` bawaan) |
| Format tanggal | `intl` |

`pubspec.yaml` (dependensi inti):

```yaml
environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
  http: ^1.2.0
  shared_preferences: ^2.2.0
  go_router: ^14.0.0
  intl: ^0.19.0
```

### 8.3 Struktur Folder (Backend & Frontend Dipisah)

Proyek dibagi menjadi dua folder terpisah dalam satu repository GitHub (*monorepo*). Keduanya dapat juga dijadikan dua repository berbeda bila tim lebih nyaman.

```
inventaris-barang-kantor/
├── README.md
├── docs/
│   ├── PRD_Aplikasi_Inventaris_Barang_Kantor.md
│   └── desain/                  # ekspor Figma, ERD
├── database/
│   ├── schema.sql               # DDL tabel users, barang, peminjaman
│   └── seed.sql                 # data awal (akun admin, contoh barang)
├── backend/                     # REST API
└── frontend/                    # Aplikasi Flutter
```

#### 8.3.1 Frontend (Flutter / Dart)

```
frontend/
├── pubspec.yaml
├── analysis_options.yaml
├── android/
├── ios/
├── test/                        # unit & widget test
└── lib/
    ├── main.dart
    ├── core/
    │   ├── constants/           # base URL, warna, string
    │   ├── router/              # app_router.dart
    │   └── utils/               # validator, formatter
    ├── data/
    │   ├── models/              # user.dart, barang.dart, peminjaman.dart
    │   ├── services/            # api_service.dart
    │   └── repositories/        # auth_repository.dart, barang_repository.dart, peminjaman_repository.dart
    ├── providers/               # auth_provider.dart, barang_provider.dart, peminjaman_provider.dart
    └── presentation/
        ├── auth/                # login_screen.dart
        ├── admin/               # dashboard, kelola_barang, form_barang, kelola_peminjaman, laporan
        ├── karyawan/            # katalog, form_pinjam, riwayat
        └── widgets/             # komponen reusable
```

Seluruh path kode Dart pada dokumen ini (misalnya `lib/data/models/user.dart`) berada di dalam folder `frontend/`.

#### 8.3.2 Backend (REST API)

Contoh di bawah memakai **Node.js + Express** (asumsi; dapat diganti PHP/Laravel dengan pembagian lapisan yang setara).

```
backend/
├── package.json
├── .env                         # DB_HOST, DB_USER, DB_PASS, DB_NAME, JWT_SECRET (tidak di-commit)
├── .env.example
├── .gitignore
└── src/
    ├── server.js                # entry point
    ├── app.js                   # konfigurasi Express, middleware, routes
    ├── config/
    │   └── db.js                # koneksi MySQL
    ├── routes/
    │   ├── auth.routes.js
    │   ├── barang.routes.js
    │   └── peminjaman.routes.js
    ├── controllers/
    │   ├── auth.controller.js
    │   ├── barang.controller.js
    │   └── peminjaman.controller.js
    ├── models/                  # query ke tabel
    │   ├── user.model.js
    │   ├── barang.model.js
    │   └── peminjaman.model.js
    ├── middlewares/
    │   ├── auth.middleware.js   # verifikasi token
    │   ├── role.middleware.js   # batasi akses Admin / Karyawan
    │   └── error.middleware.js
    └── utils/                   # hash password, helper response
```

#### 8.3.3 Pemisahan Tanggung Jawab

| Bagian | Tanggung Jawab | Tidak Boleh |
|---|---|---|
| `frontend/` | Tampilan, state, validasi input di sisi klien, memanggil API | Mengakses MySQL langsung, menyimpan kredensial database |
| `backend/` | Autentikasi, otorisasi per role, aturan bisnis (update stok), akses MySQL | Berisi kode tampilan |
| `database/` | Skema dan data awal | — |

Komunikasi hanya lewat HTTP/JSON sesuai daftar endpoint pada bagian 9. Alamat API di frontend diatur di `frontend/lib/core/constants/` (misalnya `http://10.0.2.2:3000` untuk emulator Android).

### 8.4 Model Data (Dart)

```dart
// lib/data/models/user.dart
enum UserRole { admin, karyawan }

class User {
  final int idUser;
  final String namaLengkap;
  final String email;
  final UserRole role;

  const User({
    required this.idUser,
    required this.namaLengkap,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        idUser: json['id_user'] as int,
        namaLengkap: json['nama_lengkap'] as String,
        email: json['email'] as String,
        role: json['role'] == 'Admin' ? UserRole.admin : UserRole.karyawan,
      );
}
```

```dart
// lib/data/models/barang.dart
enum KondisiBarang { baik, rusak }

class Barang {
  final int idBarang;
  final String namaBarang;
  final String kategori;
  final int stok;
  final KondisiBarang kondisi;

  const Barang({
    required this.idBarang,
    required this.namaBarang,
    required this.kategori,
    required this.stok,
    required this.kondisi,
  });

  bool get bisaDipinjam => kondisi == KondisiBarang.baik && stok > 0;

  factory Barang.fromJson(Map<String, dynamic> json) => Barang(
        idBarang: json['id_barang'] as int,
        namaBarang: json['nama_barang'] as String,
        kategori: json['kategori'] as String,
        stok: json['stok'] as int,
        kondisi: json['kondisi'] == 'Baik'
            ? KondisiBarang.baik
            : KondisiBarang.rusak,
      );

  Map<String, dynamic> toJson() => {
        'nama_barang': namaBarang,
        'kategori': kategori,
        'stok': stok,
        'kondisi': kondisi == KondisiBarang.baik ? 'Baik' : 'Rusak',
      };
}
```

```dart
// lib/data/models/peminjaman.dart
enum StatusPinjam { menunggu, dipinjam, menungguPengembalian, selesai, ditolak }

class Peminjaman {
  final int idPinjam;
  final int idUser;
  final int idBarang;
  final int jumlah;
  final DateTime tanggalPinjam;
  final DateTime? tanggalKembali;
  final StatusPinjam status;

  const Peminjaman({
    required this.idPinjam,
    required this.idUser,
    required this.idBarang,
    required this.jumlah,
    required this.tanggalPinjam,
    this.tanggalKembali,
    required this.status,
  });

  static StatusPinjam _parseStatus(String s) {
    switch (s) {
      case 'Dipinjam':
        return StatusPinjam.dipinjam;
      case 'Menunggu Pengembalian':
        return StatusPinjam.menungguPengembalian;
      case 'Selesai':
        return StatusPinjam.selesai;
      case 'Ditolak':
        return StatusPinjam.ditolak;
      default:
        return StatusPinjam.menunggu;
    }
  }

  factory Peminjaman.fromJson(Map<String, dynamic> json) => Peminjaman(
        idPinjam: json['id_pinjam'] as int,
        idUser: json['id_user'] as int,
        idBarang: json['id_barang'] as int,
        jumlah: json['jumlah'] as int? ?? 1,
        tanggalPinjam: DateTime.parse(json['tanggal_pinjam'] as String),
        tanggalKembali: json['tanggal_kembali'] == null
            ? null
            : DateTime.parse(json['tanggal_kembali'] as String),
        status: _parseStatus(json['status'] as String),
      );
}
```

### 8.5 Layanan API (Dart)

```dart
// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.example.com'; // ganti sesuai backend
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'),
        headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(Uri.parse('$baseUrl$path'),
        headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final data = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data?['message'] ?? 'Terjadi kesalahan (${res.statusCode})');
  }
}
```

### 8.6 State Management (contoh)

```dart
// lib/providers/barang_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/barang.dart';
import '../data/repositories/barang_repository.dart';

class BarangProvider extends ChangeNotifier {
  final BarangRepository _repo;
  BarangProvider(this._repo);

  List<Barang> items = [];
  bool isLoading = false;
  String? error;

  Future<void> fetch() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repo.getAll();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tambah(Barang b) async {
    await _repo.create(b);
    await fetch();
  }

  Future<void> hapus(int id) async {
    await _repo.delete(id);
    items.removeWhere((e) => e.idBarang == id);
    notifyListeners();
  }
}
```

### 8.7 Routing & Akses Berdasarkan Role

| Route | Layar | Role |
|---|---|---|
| `/login` | LoginScreen | Publik |
| `/admin` | Dashboard Admin | Admin |
| `/admin/barang` | Daftar & CRUD Barang | Admin |
| `/admin/barang/form` | Form Tambah/Ubah Barang | Admin |
| `/admin/peminjaman` | Kelola Pengajuan | Admin |
| `/admin/laporan` | Riwayat Peminjaman | Admin |
| `/karyawan` | Katalog Barang | Karyawan |
| `/karyawan/pinjam/:idBarang` | Form Peminjaman | Karyawan |
| `/karyawan/riwayat` | Riwayat Pribadi | Karyawan |

Setelah login berhasil, aplikasi mengarahkan pengguna ke `/admin` atau `/karyawan` sesuai `role`. Route lintas role harus dialihkan (redirect) ke `/login`.

## 9. Spesifikasi Endpoint API (Usulan)

| Method | Endpoint | Fungsi | Role |
|---|---|---|---|
| POST | `/auth/login` | Login, mengembalikan token + data user | Semua |
| GET | `/barang` | Daftar barang | Semua |
| POST | `/barang` | Tambah barang | Admin |
| PUT | `/barang/{id}` | Ubah barang / kondisi | Admin |
| DELETE | `/barang/{id}` | Hapus barang | Admin |
| GET | `/peminjaman` | Admin: semua; Karyawan: milik sendiri | Semua |
| POST | `/peminjaman` | Ajukan peminjaman | Karyawan |
| PUT | `/peminjaman/{id}/setujui` | Setujui pengajuan | Admin |
| PUT | `/peminjaman/{id}/tolak` | Tolak pengajuan | Admin |
| PUT | `/peminjaman/{id}/ajukan-kembali` | Ajukan pengembalian | Karyawan |
| PUT | `/peminjaman/{id}/selesai` | Konfirmasi pengembalian | Admin |

## 10. Kebutuhan UI/UX

- Desain dibuat di **Figma** sebelum implementasi; mengikuti Material Design 3.
- Layar utama: Login, Dashboard Admin, Daftar Barang, Form Barang, Daftar Pengajuan, Laporan, Katalog, Form Pinjam, Riwayat.
- Badge warna untuk kondisi (Baik = hijau, Rusak = merah) dan status peminjaman.
- Tampilkan *loading*, *empty state*, dan pesan *error* yang jelas pada setiap daftar.
- Validasi form: field wajib, format email, stok tidak boleh negatif, tanggal valid.
- Konfirmasi sebelum aksi destruktif (hapus barang, tolak pengajuan).

## 11. Kebutuhan Non-Fungsional

| Aspek | Kebutuhan |
|---|---|
| Keamanan | Password di-hash (bcrypt), komunikasi HTTPS, token autentikasi, otorisasi per role di sisi server |
| Kinerja | Daftar dimuat < 3 detik pada koneksi normal; gunakan `ListView.builder` |
| Kompatibilitas | Android 8.0+ (prioritas), iOS opsional |
| Keandalan | Penanganan error jaringan dan *timeout* |
| Maintainability | Kode terstruktur per layer, penamaan konsisten, version control di GitHub |

## 12. Rencana Pengujian

| Jenis | Cakupan |
|---|---|
| Unit test | Parsing model (`fromJson`), logika `bisaDipinjam`, provider |
| Widget test | Login, form barang, form pinjam |
| Manual / UAT | Alur lengkap pinjam → setujui → kembali → selesai untuk kedua role |

## 13. Rencana Pengerjaan (Usulan)

| Fase | Aktivitas | Output |
|---|---|---|
| 1 | Analisis & desain (Figma, ERD) | Mockup, skema final |
| 2 | Backend API + database | Endpoint berfungsi |
| 3 | Autentikasi & struktur Flutter | Login + routing per role |
| 4 | Modul Admin | CRUD barang, kelola peminjaman, laporan |
| 5 | Modul Karyawan | Katalog, pinjam, kembali, riwayat |
| 6 | Pengujian & perbaikan | Aplikasi siap demo |
| 7 | Dokumentasi & presentasi | Laporan akhir |

## 14. Risiko & Asumsi

| Risiko / Asumsi | Mitigasi |
|---|---|
| Koneksi langsung Flutter ke MySQL tidak aman | Gunakan REST API sebagai perantara |
| Skema database belum mencakup status "Ditolak" dan jumlah pinjam | Terapkan revisi skema pada bagian 7.4 |
| Stok tidak konsisten saat banyak pengajuan | Update stok dalam transaksi database di sisi server |
| Waktu pengerjaan terbatas | Prioritaskan fitur *Must*, laporan (A-05) sebagai *Should* |

## 15. Daftar Periksa Penerimaan (Acceptance Criteria)

- [ ] Admin dan karyawan dapat login dan diarahkan sesuai role.
- [ ] Admin dapat menambah, melihat, mengubah, dan menghapus barang.
- [ ] Karyawan melihat katalog dengan kondisi barang.
- [ ] Karyawan dapat mengajukan peminjaman dan pengembalian.
- [ ] Admin dapat menyetujui/menolak pengajuan dan stok ter-update dengan benar.
- [ ] Admin dapat mengubah kondisi barang.
- [ ] Riwayat peminjaman tampil untuk admin (semua) dan karyawan (milik sendiri).
- [ ] Barang rusak atau stok 0 tidak dapat dipinjam.
