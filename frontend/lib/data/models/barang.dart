class Barang {
  const Barang({
    required this.idBarang,
    required this.namaBarang,
    required this.kategori,
    required this.stok,
    required this.kondisi,
  });

  final int idBarang;
  final String namaBarang;
  final String kategori;
  final int stok;
  final String kondisi;

  bool get isRusak => kondisi == 'Rusak';
  bool get bisaDipinjam => kondisi == 'Baik' && stok > 0;

  factory Barang.fromJson(Map<String, dynamic> json) => Barang(
        idBarang: _toInt(json['id_barang']),
        namaBarang: json['nama_barang'] as String? ?? '',
        kategori: json['kategori'] as String? ?? '',
        stok: _toInt(json['stok']),
        kondisi: json['kondisi'] as String? ?? 'Baik',
      );

  Map<String, dynamic> toJson() => {
        'nama_barang': namaBarang,
        'kategori': kategori,
        'stok': stok,
        'kondisi': kondisi,
      };
}

int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
