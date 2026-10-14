class Validators {
  static String? required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
    return ok ? null : 'Format email tidak valid';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    return null;
  }

  static String? nonNegativeInt(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    final n = int.tryParse(value.trim());
    if (n == null) return '$field harus berupa angka bulat';
    if (n < 0) return '$field tidak boleh negatif';
    return null;
  }

  static String? positiveInt(String? value, String field, {int? max}) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    final n = int.tryParse(value.trim());
    if (n == null) return '$field harus berupa angka bulat';
    if (n <= 0) return '$field harus lebih dari 0';
    if (max != null && n > max) return '$field maksimal $max';
    return null;
  }
}
