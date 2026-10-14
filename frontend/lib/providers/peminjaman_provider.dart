import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../data/models/peminjaman.dart';
import '../data/repositories/peminjaman_repository.dart';
import '../data/services/api_service.dart';

class PeminjamanProvider extends ChangeNotifier {
  PeminjamanProvider(this._repo);
  final PeminjamanRepository _repo;

  List<Peminjaman> _items = [];
  bool _loading = false;
  String? _error;

  List<Peminjaman> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  List<Peminjaman> byStatus(String status) =>
      _items.where((p) => p.status == status).toList();

  int get jumlahMenunggu => byStatus(StatusPeminjaman.menunggu).length;
  int get jumlahMenungguPengembalian =>
      byStatus(StatusPeminjaman.menungguPengembalian).length;

  void clear() {
    _items = [];
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.getAll();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Gagal memuat data peminjaman.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> ajukan({
    required int idBarang,
    required int jumlah,
    required String tanggalPinjam,
  }) =>
      _run(() => _repo.ajukan(
          idBarang: idBarang, jumlah: jumlah, tanggalPinjam: tanggalPinjam));

  Future<String?> setujui(int id) => _run(() => _repo.setujui(id));
  Future<String?> tolak(int id) => _run(() => _repo.tolak(id));
  Future<String?> ajukanKembali(int id) => _run(() => _repo.ajukanKembali(id));
  Future<String?> selesai(int id, {String? kondisi}) =>
      _run(() => _repo.selesai(id, kondisi: kondisi));

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
