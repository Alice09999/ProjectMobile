import 'package:bcrypt/bcrypt.dart';
import 'package:mysql1/mysql1.dart';

import '../lib/src/config.dart';

Future<void> main(List<String> args) async {
  if (args.length != 4) {
    throw ArgumentError(
      'Penggunaan: dart run tool/create_user.dart <Admin|Karyawan> "Nama" email password',
    );
  }
  final role = args[0];
  final name = args[1].trim();
  final email = args[2].trim().toLowerCase();
  final password = args[3];
  if (role != 'Admin' && role != 'Karyawan') {
    throw ArgumentError('Role harus Admin atau Karyawan.');
  }
  if (name.isEmpty || name.length > 100) {
    throw ArgumentError('Nama wajib diisi dan maksimal 100 karakter.');
  }
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    throw ArgumentError('Format email tidak valid.');
  }
  if (password.length < 12) {
    throw ArgumentError('Password harus memiliki minimal 12 karakter.');
  }

  final host = environment('DB_HOST');
  final user = environment('DB_USER');
  final database = environment('DB_NAME');
  if (host == null || user == null || database == null) {
    throw StateError('DB_HOST, DB_USER, dan DB_NAME harus dikonfigurasi.');
  }

  final connection = await MySqlConnection.connect(ConnectionSettings(
    host: host,
    port: int.tryParse(environment('DB_PORT', fallback: '3306')!) ?? 3306,
    user: user,
    password: dbPassword(),
    db: database,
  ));
  try {
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    await connection.query(
      'INSERT INTO users (nama_lengkap, email, password, role) VALUES (?, ?, ?, ?)',
      [name, email, hash, role],
    );
    print('Akun $role $email berhasil dibuat.');
  } finally {
    await connection.close();
  }
}
