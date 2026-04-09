import 'package:shared_preferences/shared_preferences.dart';

// Simpan & ambil token login dari penyimpanan HP
class TokenStorage {
  static const String _tokenKey = 'auth_token';

  // Simpan token (dipanggil habis login/register sukses)
  static Future<void> saveToken(String token) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Ambil token (dipanggil pas mau request ke API)
  static Future<String?> getToken() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Cek apakah user udah login
  static Future<bool> hasToken() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // Hapus token (dipanggil pas logout)
  static Future<void> deleteToken() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
