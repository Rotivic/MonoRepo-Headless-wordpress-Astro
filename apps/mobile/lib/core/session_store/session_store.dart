import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  SessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _emailKey = 'user_email';
  static const _passwordKey = 'user_password';
  static const _userIdKey = 'user_id';
  static const _localeKey = 'app_locale';
  static const _themeModeKey = 'app_theme_mode';

  String? _token;
  String? _email;
  String? _password;
  int? _userId;
  String? _localeCode;
  ThemeMode _themeMode = ThemeMode.system;

  String? get token => _token;
  String? get email => _email;
  String? get password => _password;
  int? get userId => _userId;
  String? get localeCode => _localeCode;
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    _token = await _storage.read(key: _tokenKey);
    _email = await _storage.read(key: _emailKey);
    _password = await _storage.read(key: _passwordKey);
    final idStr = await _storage.read(key: _userIdKey);
    _userId = idStr != null ? int.tryParse(idStr) : null;

    _localeCode = await _storage.read(key: _localeKey);
    final themeStr = await _storage.read(key: _themeModeKey);
    _themeMode = _parseThemeMode(themeStr);
  }

  Future<void> saveCredentials({
    String? token,
    required String email,
    required String password,
    required int userId,
  }) async {
    _token = token;
    _email = email;
    _password = password;
    _userId = userId;

    await _storage.write(key: _tokenKey, value: token ?? '');
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  Future<void> saveLocale(String? code) async {
    _localeCode = code;
    await _storage.write(key: _localeKey, value: code ?? '');
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.write(key: _themeModeKey, value: mode.name);
  }

  ThemeMode _parseThemeMode(String? value) {
    if (value == null || value.isEmpty) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> clear() async {
    _token = null;
    _email = null;
    _password = null;
    _userId = null;
    // No borramos idioma ni tema al cerrar sesión por comodidad
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _userIdKey);
  }

  bool get hasCredentials => _email != null && _password != null;
}
