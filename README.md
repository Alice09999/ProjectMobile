# Aplikasi Inventaris Barang Kantor

Monorepo aplikasi inventaris barang kantor. Backend REST API memakai Dart dan Dart Frog, database memakai MySQL, dan aplikasi klien direncanakan memakai Flutter.

## Menjalankan backend

1. Jalankan `database/schema.sql` pada MySQL untuk membuat database dan tabel.
2. Salin `backend/.env.example` ke `backend/.env`, lalu isi konfigurasi MySQL dan `JWT_SECRET` acak dengan minimal 32 karakter.
3. Dari folder `backend`, jalankan `dart pub get`.
4. Pasang Dart Frog CLI jika belum tersedia: `dart pub global activate dart_frog_cli`.
5. Buat akun admin: `dart run tool/create_user.dart Admin "Nama Admin" admin@example.com "password-kuat-minimal-12"`.
6. Buat akun karyawan dengan perintah yang sama dan role `Karyawan`.
7. (Opsional) Isi barang contoh melalui `database/seed.sql`.
8. Jalankan API dari folder `backend` dengan `dart_frog dev`; server development default berjalan pada port `8080`.

Di produksi, atur variabel environment yang sama pada host dan jalankan backend menggunakan runtime/deployment Dart Frog. Jangan commit file `.env`.

## Endpoint

Semua request dan response menggunakan JSON. Selain `POST /auth/login` dan `GET /health`, endpoint memerlukan header `Authorization` berisi token JWT dengan skema Bearer. Response sukses mengembalikan data di properti `data`; error mengembalikan `message`.

| Method | Endpoint | Akses |
|---|---|---|
| POST | `/auth/login` | Publik |
| GET | `/health` | Publik |
| GET | `/barang` | Admin, Karyawan |
| POST | `/barang` | Admin |
| PUT | `/barang/:id` | Admin |
| DELETE | `/barang/:id` | Admin |
| GET | `/peminjaman` | Admin (semua), Karyawan (milik sendiri) |
| POST | `/peminjaman` | Karyawan |
| PUT | `/peminjaman/:id/setujui` | Admin |
| PUT | `/peminjaman/:id/tolak` | Admin |
| PUT | `/peminjaman/:id/ajukan-kembali` | Karyawan (milik sendiri) |
| PUT | `/peminjaman/:id/selesai` | Admin |

Body barang: `{"nama_barang":"Laptop","kategori":"Elektronik","stok":5,"kondisi":"Baik"}`.

Body pengajuan peminjaman: `{"id_barang":1,"jumlah":1,"tanggal_pinjam":"2025-01-31"}`. Saat menyelesaikan pengembalian, body `{"kondisi":"Baik"}` atau `{"kondisi":"Rusak"}` bersifat opsional; jika disertakan, kondisi barang diperbarui.

Persetujuan dan penyelesaian peminjaman mengunci row yang relevan dan memperbarui status serta stok dalam transaksi database, sehingga stok tidak menjadi negatif akibat persetujuan bersamaan. Riwayat peminjaman mencegah barang dihapus.

## Pengujian

Jalankan `dart test` dari folder `backend`.
