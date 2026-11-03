import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = "jwt";
  static const String _userIdKey = "user_id";
  static const String _emailKey = "email";
  static const String _nameKey = "name"; // 🔥 EKLENDİ

  // =====================
  // MEMORY CACHE
  // =====================
  static String? _token;
  static int? _userId;
  static String? _name; // 🔥

  // =====================
  // LOAD (APP START)
  // =====================
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getInt(_userIdKey);
    _name = prefs.getString(_nameKey);
  }

  // =====================
  // TOKEN
  // =====================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token.trim();
    await prefs.setString(_tokenKey, _token!);
  }

  static Future<String?> getToken() async {
    if (_token != null && _token!.isNotEmpty) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token;
  }

  static String? getTokenSync() => _token;

  // =====================
  // USER ID
  // =====================
  static Future<void> saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = id;
    await prefs.setInt(_userIdKey, id);
  }

  static Future<int?> getUserId() async {
    if (_userId != null) return _userId;
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt(_userIdKey);
    return _userId;
  }

  static int? getUserIdSync() => _userId;

  // =====================
  // EMAIL
  // =====================
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // =====================
  // NAME 🔥
  // =====================
  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    _name = name.trim();
    await prefs.setString(_nameKey, _name!);
  }

  static Future<String?> getName() async {
    if (_name != null && _name!.isNotEmpty) return _name;
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_nameKey);
    return _name;
  }

  // =====================
  // LOGOUT
  // =====================
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _userId = null;
    _name = null;
    await prefs.clear();
  }
}
