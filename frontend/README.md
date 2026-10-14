# Frontend — Aplikasi Inventaris Barang Kantor (Flutter)

Aplikasi mobile Flutter yang terhubung ke backend Dart Frog (`../backend`).

## Cara menjalankan

1. Pastikan backend sudah jalan (`dart_frog dev` di folder `backend`, port 8080).
2. Dari folder `frontend`, **sekali saja** buat folder platform (android/ios/web):
   ```
   flutter create . --project-name inventaris_frontend --org id.ac.polinela
   ```
   (Perintah ini tidak menimpa file di `lib/`, `pubspec.yaml`, dan `test/`.)
3. Ambil dependensi: `flutter pub get`
4. Jalankan:
   - Emulator Android: `flutter run` (default memakai `http://10.0.2.2:8080`)
   - HP asli / alamat lain:
     `flutter run --dart-define=API_BASE_URL=http://IP-LAPTOP:8080`
   - Chrome/Web: `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080`
5. Test: `flutter test`

Catatan Android: karena backend memakai `http` (bukan https), tambahkan di
`android/app/src/main/AndroidManifest.xml`:
- di atas `<application>`: `<uses-permission android:name="android.permission.INTERNET"/>`
- di tag `<application ...>`: `android:usesCleartextTraffic="true"`

Login memakai akun yang dibuat dengan `backend/tool/create_user.dart`.

## Struktur

```
lib/
├── main.dart
├── core/{constants,router,utils}
├── data/{models,services,repositories}
├── providers/        # auth, barang, peminjaman (provider + ChangeNotifier)
└── presentation/
    ├── auth/         # login
    ├── admin/        # dashboard, kelola barang, form barang, kelola peminjaman, laporan
    ├── karyawan/     # katalog, form pinjam, riwayat
    └── widgets/      # badge, loading/empty/error, dialog
```

## Rute & hak akses

| Route | Layar | Role |
|---|---|---|
| /login | Login | Publik |
| /admin | Dashboard | Admin |
| /admin/barang | Kelola barang | Admin |
| /admin/barang/form | Tambah/ubah barang | Admin |
| /admin/peminjaman | Setujui/tolak & konfirmasi pengembalian | Admin |
| /admin/laporan | Riwayat semua peminjaman | Admin |
| /karyawan | Katalog barang | Karyawan |
| /karyawan/pinjam/:idBarang | Form peminjaman | Karyawan |
| /karyawan/riwayat | Riwayat pribadi + ajukan pengembalian | Karyawan |
