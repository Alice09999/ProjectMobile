import 'dart:io';

Map<String, String>? _fileEnvironment;

String? environment(String name, {String? fallback}) {
  final systemValue = Platform.environment[name];
  if (systemValue != null && systemValue.isNotEmpty) return systemValue;

  _fileEnvironment ??= _readEnvironmentFile();
  return _fileEnvironment![name] ?? fallback;
}

Map<String, String> _readEnvironmentFile() {
  final file = File('.env');
  if (!file.existsSync()) return {};

  final values = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final separator = trimmed.indexOf('=');
    if (separator <= 0) continue;
    final key = trimmed.substring(0, separator).trim();
    var value = trimmed.substring(separator + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    values[key] = value;
  }
  return values;
}

/// Password MySQL. Mengembalikan null jika kosong, karena library mysql1
/// menganggap password '' sebagai "pakai password" (error 1045 di XAMPP).
String? dbPassword() {
  final value = environment('DB_PASSWORD');
  return (value == null || value.isEmpty) ? null : value;
}
