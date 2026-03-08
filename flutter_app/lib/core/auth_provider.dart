import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'constants.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _user?.role?.toLowerCase() == 'admin';

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    _error = err;
    notifyListeners();
  }

  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    final userData = prefs.getString(AppConstants.userKey);
    if (userData != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userData));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _api.post(
        AppConstants.login,
        data: {'username': username, 'password': password},
      );
      _token = data['access'];
      final refreshToken = data['refresh'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _token!);
      if (refreshToken != null) {
        await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
      }
      if (data['user'] != null) {
        _user = UserModel.fromJson(data['user']);
        await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      } else {
        await loadProfile();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _api.post(AppConstants.register, data: data);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProfile() async {
    try {
      final data = await _api.get(AppConstants.profile);
      _user = UserModel.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _setLoading(true);
    _setError(null);
    try {
      await _api.post(
        AppConstants.changePassword,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
    _token = null;
    _user = null;
    notifyListeners();
  }
}
