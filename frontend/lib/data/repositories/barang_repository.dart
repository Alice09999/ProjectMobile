import '../models/barang.dart';
import '../services/api_service.dart';

class BarangRepository {
  BarangRepository(this._api);
  final ApiService _api;

  Future<List<Barang>> getAll() async {
    final res = await _api.get('/barang') as Map<String, dynamic>;
    return (res['data'] as List)
        .map((e) => Barang.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(Barang b) => _api.post('/barang', b.toJson());

  Future<void> update(int id, Barang b) => _api.put('/barang/$id', b.toJson());

  Future<void> delete(int id) => _api.delete('/barang/$id');
}
