import 'package:flutter/material.dart';

class AppConstants {
  /// Alamat backend Dart Frog.
  /// - Emulator Android : http://10.0.2.2:8080 (default)
  /// - iOS Simulator / Web / Desktop : http://localhost:8080
  /// - HP asli (satu WiFi dengan laptop) : http://IP-LAPTOP:8080
  ///
  /// Ubah tanpa edit kode:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  static const String roleAdmin = 'Admin';
  static const String roleKaryawan = 'Karyawan';

  static const List<String> kondisiList = ['Baik', 'Rusak'];
}

class AppColors {
  static const Color primary = Color(0xFF1565C0);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFC62828);
  static const Color warning = Color(0xFFEF6C00);
  static const Color info = Color(0xFF0277BD);
  static const Color neutral = Color(0xFF616161);
}

class StatusPeminjaman {
  static const String menunggu = 'Menunggu';
  static const String dipinjam = 'Dipinjam';
  static const String menungguPengembalian = 'Menunggu Pengembalian';
  static const String selesai = 'Selesai';
  static const String ditolak = 'Ditolak';

  static const List<String> semua = [
    menunggu,
    dipinjam,
    menungguPengembalian,
    selesai,
    ditolak,
  ];
}
