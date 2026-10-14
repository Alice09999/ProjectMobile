import 'package:mysql1/mysql1.dart';
import 'config.dart';

Future<MySqlConnection> openConnection() {
  final host = environment('DB_HOST');
  final user = environment('DB_USER');
  final database = environment('DB_NAME');
  if (host == null || user == null || database == null) {
    throw StateError('DB_HOST, DB_USER, dan DB_NAME harus dikonfigurasi.');
  }

  return MySqlConnection.connect(
    ConnectionSettings(
      host: host,
      port: int.tryParse(environment('DB_PORT', fallback: '3306')!) ?? 3306,
      user: user,
      password: dbPassword(),
      db: database,
    ),
  );
}

Future<T> withConnection<T>(Future<T> Function(MySqlConnection) action) async {
  final connection = await openConnection();
  try {
    return await action(connection);
  } finally {
    await connection.close();
  }
}

Future<T> withTransaction<T>(
  Future<T> Function(MySqlConnection) action,
) async {
  return withConnection((connection) async {
    await connection.query('START TRANSACTION');
    try {
      final result = await action(connection);
      await connection.query('COMMIT');
      return result;
    } catch (_) {
      await connection.query('ROLLBACK');
      rethrow;
    }
  });
}

// Bagian ini yang diperbaiki: 'Row' diganti menjadi 'ResultRow'
Map<String, dynamic> rowMap(ResultRow row, List<String> columns) { 
  return {
    for (var index = 0; index < columns.length; index++)
      columns[index]: row[index],
  };
}

List<Map<String, dynamic>> rowsMap(Results rows, List<String> columns) {
  return rows.map((row) => rowMap(row, columns)).toList();
}