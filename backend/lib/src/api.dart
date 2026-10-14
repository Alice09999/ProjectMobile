import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mysql1/mysql1.dart';

import 'config.dart';
import 'database.dart';

const barangColumns = [
  'id_barang',
  'nama_barang',
  'kategori',
  'stok',
  'kondisi',
];

const peminjamanColumns = [
  'id_pinjam',
  'id_user',
  'id_barang',
  'jumlah',
  'tanggal_pinjam',
  'tanggal_kembali',
  'status',
  'nama_lengkap',
  'email',
  'nama_barang',
  'kategori',
  'kondisi',
];

class ApiException implements Exception {
  const ApiException(this.status, this.message);

  final int status;
  final String message;
}

class Principal {
  const Principal(this.userId, this.role);

  final int userId;
  final String role;
}

Response jsonResponse(
  Map<String, dynamic> body, {
  int status = 200,
}) =>
    Response.json(statusCode: status, body: body);

Future<Response> handle(Future<Response> Function() action) async {
  try {
    return await action();
  } on ApiException catch (error) {
    return jsonResponse({'message': error.message}, status: error.status);
  } catch (error, stackTrace) {
    // Internal errors are logged while the response avoids leaking details.
    print('API error: $error\n$stackTrace');
    return jsonResponse(
      {'message': 'Terjadi kesalahan pada server.'},
      status: 500,
    );
  }
}

Future<Map<String, dynamic>> requestBody(RequestContext context) async {
  try {
    final value = await context.request.json();
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
  } on FormatException {
    throw const ApiException(400, 'Body harus berupa JSON yang valid.');
  }
  throw const ApiException(400, 'Body harus berupa objek JSON.');
}

String requiredText(dynamic value, String field, int maxLength) {
  if (value is! String || value.trim().isEmpty) {
    throw ApiException(400, '$field wajib diisi.');
  }
  final result = value.trim();
  if (result.length > maxLength) {
    throw ApiException(400, '$field maksimal $maxLength karakter.');
  }
  return result;
}

String requiredPassword(dynamic value) {
  if (value is! String || value.isEmpty) {
    throw const ApiException(400, 'Password wajib diisi.');
  }
  if (value.length > 200) {
    throw const ApiException(400, 'Password maksimal 200 karakter.');
  }
  return value;
}

int positiveInteger(dynamic value, String field) {
  final number = value is int ? value : int.tryParse('$value');
  if (number == null || number <= 0) {
    throw ApiException(400, '$field harus berupa bilangan bulat positif.');
  }
  return number;
}

int nonNegativeInteger(dynamic value, String field) {
  final number = value is int ? value : int.tryParse('$value');
  if (number == null || number < 0) {
    throw ApiException(400, '$field harus berupa bilangan bulat nol atau lebih.');
  }
  return number;
}

String enumValue(dynamic value, String field, List<String> allowed) {
  if (value is! String || !allowed.contains(value)) {
    throw ApiException(400, '$field harus salah satu dari: ${allowed.join(', ')}.');
  }
  return value;
}

String isoDate(dynamic value, String field) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw ApiException(400, '$field harus berformat YYYY-MM-DD.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.toIso8601String().substring(0, 10) != value) {
    throw ApiException(400, '$field bukan tanggal yang valid.');
  }
  return value;
}

int parseId(String raw, {String field = 'ID'}) {
  final value = int.tryParse(raw);
  if (value == null || value <= 0) throw ApiException(400, '$field tidak valid.');
  return value;
}

Principal authorize(
  RequestContext context, {
  List<String>? roles,
}) {
  final authorization = context.request.headers['authorization'];
  final match = authorization == null
      ? null
      : RegExp(r'^Bearer\s+(.+)$', caseSensitive: false).firstMatch(authorization);
  if (match == null) throw const ApiException(401, 'Token autentikasi diperlukan.');

  final secret = environment('JWT_SECRET');
  if (secret == null || secret.length < 32) {
    throw StateError('JWT_SECRET harus memiliki minimal 32 karakter.');
  }
  try {
    final verified = JWT.verify(match.group(1)!, SecretKey(secret));
    final userId = int.tryParse('${verified.payload['sub']}');
    final role = verified.payload['role'];
    if (userId == null || (role != 'Admin' && role != 'Karyawan')) {
      throw const ApiException(401, 'Token tidak valid atau sudah kedaluwarsa.');
    }
    if (roles != null && !roles.contains(role)) {
      throw const ApiException(403, 'Anda tidak memiliki akses untuk tindakan ini.');
    }
    return Principal(userId, role as String);
  } on ApiException {
    rethrow;
  } catch (_) {
    throw const ApiException(401, 'Token tidak valid atau sudah kedaluwarsa.');
  }
}

Response methodNotAllowed() =>
    jsonResponse({'message': 'Method tidak diizinkan.'}, status: 405);

Future<Response> login(RequestContext context) => handle(() async {
      final body = await requestBody(context);
      final email = requiredText(body['email'], 'Email', 100).toLowerCase();
      final password = requiredPassword(body['password']);
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        throw const ApiException(400, 'Format email tidak valid.');
      }

      final user = await withConnection((connection) async {
        final rows = await connection.query(
          'SELECT id_user, nama_lengkap, email, password, role '
          'FROM users WHERE email = ? LIMIT 1',
          [email],
        );
        if (rows.isEmpty) return null;
        return rowMap(
          rows.first,
          ['id_user', 'nama_lengkap', 'email', 'password', 'role'],
        );
      });
      if (user == null || !BCrypt.checkpw(password, user['password'] as String)) {
        throw const ApiException(401, 'Email atau password salah.');
      }

      final secret = environment('JWT_SECRET');
      if (secret == null || secret.length < 32) {
        throw StateError('JWT_SECRET harus memiliki minimal 32 karakter.');
      }
      final expiresHours =
          int.tryParse(environment('JWT_EXPIRES_HOURS', fallback: '8')!) ?? 8;
      final jwt = JWT({
        'sub': '${user['id_user']}',
        'role': user['role'],
      });
      final token = jwt.sign(
        SecretKey(secret),
        expiresIn: Duration(hours: expiresHours),
      );
      return jsonResponse({
        'message': 'Login berhasil.',
        'data': {
          'token': token,
          'user': {
            'id_user': user['id_user'],
            'nama_lengkap': user['nama_lengkap'],
            'email': user['email'],
            'role': user['role'],
          },
        },
      });
    });

Future<Response> listBarang(RequestContext context) => handle(() async {
      authorize(context);
      final rows = await withConnection(
        (connection) => connection.query(
          'SELECT id_barang, nama_barang, kategori, stok, kondisi '
          'FROM barang ORDER BY id_barang DESC',
        ),
      );
      return jsonResponse({'data': rowsMap(rows, barangColumns)});
    });

Future<Response> createBarang(RequestContext context) => handle(() async {
      authorize(context, roles: ['Admin']);
      final data = parseBarang(await requestBody(context));
      final created = await withConnection((connection) async {
        final result = await connection.query(
          'INSERT INTO barang (nama_barang, kategori, stok, kondisi) '
          'VALUES (?, ?, ?, ?)',
          [data['nama_barang'], data['kategori'], data['stok'], data['kondisi']],
        );
        final id = result.insertId;
        if (id == null) throw StateError('Database tidak mengembalikan ID barang baru.');
        final rows = await connection.query(
          'SELECT id_barang, nama_barang, kategori, stok, kondisi '
          'FROM barang WHERE id_barang = ?',
          [id],
        );
        return rowsMap(rows, barangColumns).first;
      });
      return jsonResponse(
        {'message': 'Barang berhasil ditambahkan.', 'data': created},
        status: 201,
      );
    });

Future<Response> updateBarang(RequestContext context, String rawId) => handle(() async {
      authorize(context, roles: ['Admin']);
      final id = parseId(rawId, field: 'ID barang');
      final data = parseBarang(await requestBody(context));
      final updated = await withConnection((connection) async {
        final result = await connection.query(
          'UPDATE barang SET nama_barang = ?, kategori = ?, stok = ?, kondisi = ? '
          'WHERE id_barang = ?',
          [data['nama_barang'], data['kategori'], data['stok'], data['kondisi'], id],
        );
        if ((result.affectedRows ?? 0) == 0) {
          final existing = await connection.query(
            'SELECT id_barang FROM barang WHERE id_barang = ?',
            [id],
          );
          if (existing.isEmpty) return null;
        }
        final rows = await connection.query(
          'SELECT id_barang, nama_barang, kategori, stok, kondisi '
          'FROM barang WHERE id_barang = ?',
          [id],
        );
        return rowsMap(rows, barangColumns).first;
      });
      if (updated == null) throw const ApiException(404, 'Barang tidak ditemukan.');
      return jsonResponse({'message': 'Barang berhasil diperbarui.', 'data': updated});
    });

Future<Response> deleteBarang(RequestContext context, String rawId) => handle(() async {
      authorize(context, roles: ['Admin']);
      final id = parseId(rawId, field: 'ID barang');
      await withTransaction((connection) async {
        final locked = await connection.query(
          'SELECT id_barang FROM barang WHERE id_barang = ? FOR UPDATE',
          [id],
        );
        if (locked.isEmpty) {
          throw const ApiException(404, 'Barang tidak ditemukan.');
        }
        final references = await connection.query(
          'SELECT COUNT(*) FROM peminjaman WHERE id_barang = ?',
          [id],
        );
        if ((references.first[0] as int) > 0) {
          throw const ApiException(
            409,
            'Barang tidak dapat dihapus karena memiliki riwayat peminjaman.',
          );
        }
        final result = await connection.query('DELETE FROM barang WHERE id_barang = ?', [id]);
        if ((result.affectedRows ?? 0) == 0) {
          throw const ApiException(404, 'Barang tidak ditemukan.');
        }
      });
      return jsonResponse({'message': 'Barang berhasil dihapus.'});
    });

Map<String, dynamic> parseBarang(Map<String, dynamic> body) {
  return {
    'nama_barang': requiredText(body['nama_barang'], 'Nama barang', 100),
    'kategori': requiredText(body['kategori'], 'Kategori', 50),
    'stok': nonNegativeInteger(body['stok'], 'Stok'),
    'kondisi': enumValue(body['kondisi'] ?? 'Baik', 'Kondisi', ['Baik', 'Rusak']),
  };
}

Future<Response> listPeminjaman(RequestContext context) => handle(() async {
      final principal = authorize(context);
      final rows = await withConnection((connection) async {
        final query = principal.role == 'Admin'
            ? 'SELECT p.id_pinjam, p.id_user, p.id_barang, p.jumlah, '
                'DATE_FORMAT(p.tanggal_pinjam, \'%Y-%m-%d\'), '
                'DATE_FORMAT(p.tanggal_kembali, \'%Y-%m-%d\'), p.status, '
                'u.nama_lengkap, u.email, b.nama_barang, b.kategori, b.kondisi '
                'FROM peminjaman p INNER JOIN users u ON u.id_user = p.id_user '
                'INNER JOIN barang b ON b.id_barang = p.id_barang '
                'ORDER BY p.id_pinjam DESC'
            : 'SELECT p.id_pinjam, p.id_user, p.id_barang, p.jumlah, '
                'DATE_FORMAT(p.tanggal_pinjam, \'%Y-%m-%d\'), '
                'DATE_FORMAT(p.tanggal_kembali, \'%Y-%m-%d\'), p.status, '
                'u.nama_lengkap, u.email, b.nama_barang, b.kategori, b.kondisi '
                'FROM peminjaman p INNER JOIN users u ON u.id_user = p.id_user '
                'INNER JOIN barang b ON b.id_barang = p.id_barang '
                'WHERE p.id_user = ? ORDER BY p.id_pinjam DESC';
        final result = principal.role == 'Admin'
            ? await connection.query(query)
            : await connection.query(query, [principal.userId]);
        return rowsMap(result, peminjamanColumns);
      });
      return jsonResponse({'data': rows});
    });

Future<Response> createPeminjaman(RequestContext context) => handle(() async {
      final principal = authorize(context, roles: ['Karyawan']);
      final body = await requestBody(context);
      final idBarang = positiveInteger(body['id_barang'], 'ID barang');
      final jumlah = positiveInteger(body['jumlah'], 'Jumlah');
      final tanggal = isoDate(body['tanggal_pinjam'], 'Tanggal pinjam');

      final id = await withTransaction((connection) async {
        final items = await connection.query(
          'SELECT id_barang, stok, kondisi FROM barang WHERE id_barang = ? FOR UPDATE',
          [idBarang],
        );
        if (items.isEmpty) throw const ApiException(404, 'Barang tidak ditemukan.');
        final item = items.first;
        final stok = item[1] as int;
        final kondisi = item[2] as String;
        if (kondisi == 'Rusak' || stok == 0) {
          throw const ApiException(409, 'Barang rusak atau stok habis, tidak dapat dipinjam.');
        }
        if (jumlah > stok) {
          throw const ApiException(409, 'Jumlah pengajuan melebihi stok yang tersedia.');
        }
        final result = await connection.query(
          "INSERT INTO peminjaman "
          "(id_user, id_barang, jumlah, tanggal_pinjam, status) "
          "VALUES (?, ?, ?, ?, 'Menunggu')",
          [principal.userId, idBarang, jumlah, tanggal],
        );
        final id = result.insertId;
        if (id == null) throw StateError('Database tidak mengembalikan ID peminjaman baru.');
        return id;
      });
      final created = await getPeminjaman(id);
      return jsonResponse(
        {'message': 'Pengajuan peminjaman berhasil dibuat.', 'data': created},
        status: 201,
      );
    });

Future<Map<String, dynamic>?> getPeminjaman(int id) =>
    withConnection((connection) async {
      final rows = await connection.query(
        'SELECT p.id_pinjam, p.id_user, p.id_barang, p.jumlah, '
        'DATE_FORMAT(p.tanggal_pinjam, \'%Y-%m-%d\'), '
        'DATE_FORMAT(p.tanggal_kembali, \'%Y-%m-%d\'), p.status, '
        'u.nama_lengkap, u.email, b.nama_barang, b.kategori, b.kondisi '
        'FROM peminjaman p INNER JOIN users u ON u.id_user = p.id_user '
        'INNER JOIN barang b ON b.id_barang = p.id_barang '
        'WHERE p.id_pinjam = ?',
        [id],
      );
      return rows.isEmpty ? null : rowMap(rows.first, peminjamanColumns);
    });

Future<Response> approvePeminjaman(RequestContext context, String rawId) =>
    handle(() async {
      authorize(context, roles: ['Admin']);
      final id = parseId(rawId, field: 'ID peminjaman');
      await withTransaction((connection) async {
        final requests = await connection.query(
          'SELECT id_pinjam, id_barang, jumlah, status FROM peminjaman '
          'WHERE id_pinjam = ? FOR UPDATE',
          [id],
        );
        if (requests.isEmpty) {
          throw const ApiException(404, 'Pengajuan peminjaman tidak ditemukan.');
        }
        final request = requests.first;
        if (request[3] != 'Menunggu') {
          throw const ApiException(409, 'Hanya pengajuan berstatus Menunggu yang dapat disetujui.');
        }
        final items = await connection.query(
          'SELECT stok, kondisi FROM barang WHERE id_barang = ? FOR UPDATE',
          [request[1]],
        );
        if (items.isEmpty) throw const ApiException(404, 'Barang tidak ditemukan.');
        if (items.first[1] == 'Rusak' || (items.first[0] as int) < (request[2] as int)) {
          throw const ApiException(
            409,
            'Stok atau kondisi barang tidak memungkinkan pengajuan disetujui.',
          );
        }
        await connection.query(
          'UPDATE barang SET stok = stok - ? WHERE id_barang = ?',
          [request[2], request[1]],
        );
        await connection.query(
          "UPDATE peminjaman SET status = 'Dipinjam' WHERE id_pinjam = ?",
          [id],
        );
      });
      return jsonResponse({
        'message': 'Pengajuan disetujui dan stok barang diperbarui.',
        'data': await getPeminjaman(id),
      });
    });

Future<Response> rejectPeminjaman(RequestContext context, String rawId) => handle(() async {
      authorize(context, roles: ['Admin']);
      final id = parseId(rawId, field: 'ID peminjaman');
      final updated = await withConnection((connection) async {
        final result = await connection.query(
          "UPDATE peminjaman SET status = 'Ditolak' "
          "WHERE id_pinjam = ? AND status = 'Menunggu'",
          [id],
        );
        return (result.affectedRows ?? 0) > 0;
      });
      if (!updated) {
        if (await getPeminjaman(id) == null) {
          throw const ApiException(404, 'Pengajuan peminjaman tidak ditemukan.');
        }
        throw const ApiException(409, 'Hanya pengajuan berstatus Menunggu yang dapat ditolak.');
      }
      return jsonResponse({
        'message': 'Pengajuan berhasil ditolak.',
        'data': await getPeminjaman(id),
      });
    });

Future<Response> requestReturn(RequestContext context, String rawId) => handle(() async {
      final principal = authorize(context, roles: ['Karyawan']);
      final id = parseId(rawId, field: 'ID peminjaman');
      final result = await withConnection((connection) async {
        return connection.query(
          "UPDATE peminjaman SET status = 'Menunggu Pengembalian' "
          "WHERE id_pinjam = ? AND id_user = ? AND status = 'Dipinjam'",
          [id, principal.userId],
        );
      });
      if ((result.affectedRows ?? 0) == 0) {
        final existing = await getPeminjaman(id);
        if (existing == null || existing['id_user'] != principal.userId) {
          throw const ApiException(404, 'Peminjaman tidak ditemukan.');
        }
        throw const ApiException(
          409,
          'Hanya peminjaman aktif milik Anda yang dapat diajukan pengembaliannya.',
        );
      }
      return jsonResponse({
        'message': 'Pengajuan pengembalian berhasil dibuat.',
        'data': await getPeminjaman(id),
      });
    });

Future<Response> completeReturn(RequestContext context, String rawId) => handle(() async {
      authorize(context, roles: ['Admin']);
      final id = parseId(rawId, field: 'ID peminjaman');
      final body = await requestBody(context);
      final kondisi = body['kondisi'] == null
          ? null
          : enumValue(body['kondisi'], 'Kondisi', ['Baik', 'Rusak']);
      await withTransaction((connection) async {
        final requests = await connection.query(
          'SELECT id_barang, jumlah, status FROM peminjaman '
          'WHERE id_pinjam = ? FOR UPDATE',
          [id],
        );
        if (requests.isEmpty) throw const ApiException(404, 'Peminjaman tidak ditemukan.');
        final request = requests.first;
        if (request[2] != 'Menunggu Pengembalian') {
          throw const ApiException(
            409,
            'Hanya pengajuan pengembalian yang menunggu yang dapat diselesaikan.',
          );
        }
        await connection.query(
          "UPDATE peminjaman SET status = 'Selesai', tanggal_kembali = CURRENT_DATE "
          'WHERE id_pinjam = ?',
          [id],
        );
        if (kondisi == null) {
          await connection.query(
            'UPDATE barang SET stok = stok + ? WHERE id_barang = ?',
            [request[1], request[0]],
          );
        } else {
          await connection.query(
            'UPDATE barang SET stok = stok + ?, kondisi = ? WHERE id_barang = ?',
            [request[1], kondisi, request[0]],
          );
        }
      });
      return jsonResponse({
        'message': 'Pengembalian dikonfirmasi dan stok barang diperbarui.',
        'data': await getPeminjaman(id),
      });
    });
