import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  // Nama kunci (key) buat nyimpen token di memori HP
  static const String _tokenKey = 'auth_token';

  // 1. Fungsi buat nyimpen token (Dipanggil habis Register/Login sukses)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 2. Fungsi buat ngambil token (Dipanggil pas mau nembak API Absen, Profile, dll)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 3. Fungsi buat ngecek apakah user udah login (Dipanggil pas aplikasi baru dibuka)
  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // 4. Fungsi buat ngapus token (Dipanggil pas user klik Logout)
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
