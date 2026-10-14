import 'package:flutter/foundation.dart';

import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo, this._api) {
    // Token kedaluwarsa -> otomatis keluar ke halaman login.
    _api.onUnauthorized = () => logout();
  }

  final AuthRepository _repo;
  final ApiService _api;

  User? _user;
  bool _initialized = false;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> init() async {
    final session = await _repo.restore();
    if (session != null) {
      _api.token = session.token;
      _user = session.user;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _repo.login(email, password);
      _api.token = session.token;
      _user = session.user;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Terjadi kesalahan tak terduga.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_user == null) return;
    _api.token = null;
    _user = null;
    await _repo.clear();
    notifyListeners();
  }
}
