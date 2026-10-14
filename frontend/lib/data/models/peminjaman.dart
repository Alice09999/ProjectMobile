class Peminjaman {
  const Peminjaman({
    required this.idPinjam,
    required this.idUser,
    required this.idBarang,
    required this.jumlah,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.status,
    required this.namaLengkap,
    required this.email,
    required this.namaBarang,
    required this.kategori,
    required this.kondisi,
  });

  final int idPinjam;
  final int idUser;
  final int idBarang;
  final int jumlah;
  final String tanggalPinjam;
  final String? tanggalKembali;
  final String status;
  final String namaLengkap;
  final String email;
  final String namaBarang;
  final String kategori;
  final String kondisi;

  factory Peminjaman.fromJson(Map<String, dynamic> json) => Peminjaman(
        idPinjam: _toInt(json['id_pinjam']),
        idUser: _toInt(json['id_user']),
        idBarang: _toInt(json['id_barang']),
        jumlah: _toInt(json['jumlah']),
        tanggalPinjam: json['tanggal_pinjam'] as String? ?? '',
        tanggalKembali: json['tanggal_kembali'] as String?,
        status: json['status'] as String? ?? '',
        namaLengkap: json['nama_lengkap'] as String? ?? '',
        email: json['email'] as String? ?? '',
        namaBarang: json['nama_barang'] as String? ?? '',
        kategori: json['kategori'] as String? ?? '',
        kondisi: json['kondisi'] as String? ?? '',
      );
}

int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
