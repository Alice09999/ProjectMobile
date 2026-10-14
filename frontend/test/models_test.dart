import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_frontend/core/utils/validators.dart';
import 'package:inventaris_frontend/data/models/barang.dart';
import 'package:inventaris_frontend/data/models/peminjaman.dart';

void main() {
  test('Barang.fromJson & bisaDipinjam', () {
    final b = Barang.fromJson({
      'id_barang': 1,
      'nama_barang': 'Laptop',
      'kategori': 'Elektronik',
      'stok': 3,
      'kondisi': 'Baik',
    });
    expect(b.bisaDipinjam, isTrue);
    expect(
      Barang.fromJson({...b.toJson(), 'id_barang': 2, 'stok': 0}).bisaDipinjam,
      isFalse,
    );
    expect(
      Barang.fromJson({...b.toJson(), 'id_barang': 3, 'kondisi': 'Rusak'})
          .bisaDipinjam,
      isFalse,
    );
  });

  test('Peminjaman.fromJson menerima tanggal_kembali null', () {
    final p = Peminjaman.fromJson({
      'id_pinjam': 1,
      'id_user': 2,
      'id_barang': 3,
      'jumlah': 1,
      'tanggal_pinjam': '2025-01-31',
      'tanggal_kembali': null,
      'status': 'Menunggu',
      'nama_lengkap': 'Budi',
      'email': 'budi@mail.com',
      'nama_barang': 'Laptop',
      'kategori': 'Elektronik',
      'kondisi': 'Baik',
    });
    expect(p.tanggalKembali, isNull);
    expect(p.status, 'Menunggu');
  });

  test('Validators', () {
    expect(Validators.email('salah'), isNotNull);
    expect(Validators.email('a@b.com'), isNull);
    expect(Validators.nonNegativeInt('-1', 'Stok'), isNotNull);
    expect(Validators.positiveInt('5', 'Jumlah', max: 3), isNotNull);
    expect(Validators.positiveInt('2', 'Jumlah', max: 3), isNull);
  });
}
