// Kumpulan URL API yang dipake di aplikasi
class Endpoints {
  static const String baseUrl = "https://appabsensi.mobileprojp.com";

  // Login & Register
  static const String register = "$baseUrl/api/register";
  static const String login = "$baseUrl/api/login";
  static const String forgotPassword = "$baseUrl/api/forgot-password";
  static const String resetPassword = "$baseUrl/api/reset-password";

  // Profil
  static const String profile = "$baseUrl/api/profile";
  static const String updateProfile = "$baseUrl/api/profile";
  static const String updatePhoto = "$baseUrl/api/profile/photo";

  // Absensi
  static const String checkIn = "$baseUrl/api/absen/check-in";
  static const String checkOut = "$baseUrl/api/absen/check-out";
  static const String absenToday = "$baseUrl/api/absen/today";
  static const String absenStats = "$baseUrl/api/absen/stats";
  static const String absenHistory = "$baseUrl/api/absen/history";

  // Hapus data absen berdasarkan ID
  static String deleteAbsen(int id) => "$baseUrl/api/absen/$id";

  // Izin
  static const String izin = "$baseUrl/api/izin";

  // Device Token
  static const String deviceToken = "$baseUrl/api/device-token";

  // Users
  static const String users = "$baseUrl/api/users";

  // Pelatihan
  static const String trainings = "$baseUrl/api/trainings";
  static String trainingDetail(int id) => "$baseUrl/api/trainings/$id";

  // Batch
  static const String batches = "$baseUrl/api/batches";
}
