import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Klien HTTP tunggal. Semua response backend berbentuk
/// `{ "message": "...", "data": ... }`.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);

  String? token;

  /// Dipanggil saat server membalas 401 (token kedaluwarsa/tidak valid).
  void Function()? onUnauthorized;

  Uri _uri(String path) => Uri.parse('${AppConstants.baseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) =>
      _send(() => _client.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send(
      () => _client.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) => _send(
      () => _client.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException {
      throw const ApiException(
          'Tidak dapat terhubung ke server. Periksa koneksi dan alamat API.');
    }

    Map<String, dynamic> json = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        throw ApiException('Respon server tidak valid.',
            statusCode: response.statusCode);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    if (response.statusCode == 401 && token != null) {
      onUnauthorized?.call();
    }
    throw ApiException(
      json['message'] as String? ?? 'Terjadi kesalahan (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}
