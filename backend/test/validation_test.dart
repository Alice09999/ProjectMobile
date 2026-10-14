import 'package:inventaris_backend/src/api.dart';
import 'package:test/test.dart';

void main() {
  group('API input validation', () {
    test('accepts positive integer quantities', () {
      expect(positiveInteger(2, 'Jumlah'), 2);
    });

    test('rejects zero for positive integer quantities', () {
      expect(
        () => positiveInteger(0, 'Jumlah'),
        throwsA(isA<ApiException>().having((error) => error.status, 'status', 400)),
      );
    });

    test('accepts only real ISO calendar dates', () {
      expect(isoDate('2025-02-28', 'Tanggal'), '2025-02-28');
      expect(
        () => isoDate('2025-02-30', 'Tanggal'),
        throwsA(isA<ApiException>()),
      );
    });

    test('rejects values outside enums', () {
      expect(
        () => enumValue('Tersedia', 'Kondisi', ['Baik', 'Rusak']),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
