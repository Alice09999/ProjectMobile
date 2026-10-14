import '../models/peminjaman.dart';
import '../services/api_service.dart';

class PeminjamanRepository {
  PeminjamanRepository(this._api);
  final ApiService _api;

  Future<List<Peminjaman>> getAll() async {
    final res = await _api.get('/peminjaman') as Map<String, dynamic>;
    return (res['data'] as List)
        .map((e) => Peminjaman.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> ajukan({
    required int idBarang,
    required int jumlah,
    required String tanggalPinjam,
  }) =>
      _api.post('/peminjaman', {
        'id_barang': idBarang,
        'jumlah': jumlah,
        'tanggal_pinjam': tanggalPinjam,
      });

  Future<void> setujui(int id) => _api.put('/peminjaman/$id/setujui');

  Future<void> tolak(int id) => _api.put('/peminjaman/$id/tolak');

  Future<void> ajukanKembali(int id) => _api.put('/peminjaman/$id/ajukan-kembali');

  /// [kondisi] opsional: 'Baik' / 'Rusak'. Null = kondisi barang tidak diubah.
  Future<void> selesai(int id, {String? kondisi}) =>
      _api.put('/peminjaman/$id/selesai', kondisi == null ? {} : {'kondisi': kondisi});
}
