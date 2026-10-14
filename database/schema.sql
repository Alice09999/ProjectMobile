CREATE DATABASE IF NOT EXISTS inventaris_kantor
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE inventaris_kantor;

CREATE TABLE IF NOT EXISTS users (
  id_user INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nama_lengkap VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role ENUM('Admin', 'Karyawan') NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS barang (
  id_barang INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nama_barang VARCHAR(100) NOT NULL,
  kategori VARCHAR(50) NOT NULL,
  stok INT UNSIGNED NOT NULL DEFAULT 0,
  kondisi ENUM('Baik', 'Rusak') NOT NULL DEFAULT 'Baik',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS peminjaman (
  id_pinjam INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_user INT UNSIGNED NOT NULL,
  id_barang INT UNSIGNED NOT NULL,
  jumlah INT UNSIGNED NOT NULL DEFAULT 1,
  tanggal_pinjam DATE NOT NULL,
  tanggal_kembali DATE NULL,
  status ENUM(
    'Menunggu',
    'Dipinjam',
    'Menunggu Pengembalian',
    'Selesai',
    'Ditolak'
  ) NOT NULL DEFAULT 'Menunggu',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_peminjaman_user
    FOREIGN KEY (id_user) REFERENCES users (id_user),
  CONSTRAINT fk_peminjaman_barang
    FOREIGN KEY (id_barang) REFERENCES barang (id_barang),
  INDEX idx_peminjaman_user_status (id_user, status),
  INDEX idx_peminjaman_barang_status (id_barang, status)
) ENGINE=InnoDB;
