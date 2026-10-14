import 'package:flutter/foundation.dart';

import '../data/models/barang.dart';
import '../data/repositories/barang_repository.dart';
import '../data/services/api_service.dart';

class BarangProvider extends ChangeNotifier {
  BarangProvider(this._repo);
  final BarangRepository _repo;

  List<Barang> _items = [];
  bool _loading = false;
  String? _error;

  List<Barang> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  int get totalJenis => _items.length;
  int get totalStok => _items.fold(0, (sum, b) => sum + b.stok);
  int get totalRusak => _items.where((b) => b.isRusak).length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.getAll();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Gagal memuat data barang.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Mengembalikan null bila sukses, atau pesan error.
  Future<String?> save(Barang barang, {int? id}) => _run(() async {
        if (id == null) {
          await _repo.create(barang);
        } else {
          await _repo.update(id, barang);
        }
      });

  Future<String?> remove(int id) => _run(() => _repo.delete(id));

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Terjadi kesalahan tak terduga.';
    }
  }
}
