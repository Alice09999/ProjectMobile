import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthSession {
  const AuthSession(this.token, this.user);
  final String token;
  final User user;
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiService _api;

  Future<AuthSession> login(String email, String password) async {
    final res = await _api.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    }) as Map<String, dynamic>;
    final data = res['data'] as Map<String, dynamic>;
    final session = AuthSession(
      data['token'] as String,
      User.fromJson(data['user'] as Map<String, dynamic>),
    );
    await _save(session);
    return session;
  }

  Future<AuthSession?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userJson = prefs.getString(AppConstants.userKey);
    if (token == null || userJson == null) return null;
    try {
      final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      return AuthSession(token, user);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> _save(AuthSession s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, s.token);
    await prefs.setString(AppConstants.userKey, jsonEncode(s.user.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }
}
