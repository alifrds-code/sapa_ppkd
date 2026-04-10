import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../api/endpoint.dart';
import '../shared_preferences/token_storage.dart';
import '../models/profile_model.dart';
import '../models/absen_today_model.dart';
import '../models/absen_stats_model.dart';
import '../models/absen_history_model.dart';

class DashboardService {
  // Bikin header dengan token buat semua request API
  Future<Map<String, String>> _getHeaders() async {
    var token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Ambil data profil user
  Future<ProfileModel> fetchProfile() async {
    try {
      var headers = await _getHeaders();
      var response = await http.get(
        Uri.parse(Endpoints.profile),
        headers: headers,
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ProfileModel.fromJson(jsonResponse['data']);
      } else {
        throw Exception(jsonResponse['message'] ?? "Gagal mengambil profil");
      }
    } catch (e) {
      print('fetchProfile error: $e');
      rethrow;
    }
  }

  // Ambil data absen hari ini (return null kalau belum absen)
  Future<AbsenTodayModel?> fetchAbsenToday() async {
    try {
      var headers = await _getHeaders();
      var today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      var response = await http.get(
        Uri.parse("${Endpoints.absenToday}?attendance_date=$today"),
        headers: headers,
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (jsonResponse['data'] != null) {
          return AbsenTodayModel.fromJson(jsonResponse['data']);
        }
        return null;
      } else if (response.statusCode == 404) {
        // Belum ada data absen hari ini, ini normal
        return null;
      } else {
        throw Exception(
          jsonResponse['message'] ?? "Gagal mengambil data absen",
        );
      }
    } catch (e) {
      print('fetchAbsenToday error: $e');
      return null;
    }
  }

  // Update nama profil
  Future<void> updateProfile({required String name}) async {
    try {
      var headers = await _getHeaders();
      var response = await http.put(
        Uri.parse(Endpoints.profile),
        headers: headers,
        body: jsonEncode({"name": name}),
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(jsonResponse['message'] ?? "Gagal memperbarui profil");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // Update foto profil (kirim base64)
  Future<void> updateProfilePhoto(String base64Image) async {
    try {
      var headers = await _getHeaders();

      var response = await http.put(
        Uri.parse(Endpoints.updatePhoto),
        headers: headers,
        body: jsonEncode({"profile_photo": base64Image}),
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          jsonResponse['message'] ?? "Gagal memperbarui foto profil",
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // Ambil statistik absen bulan ini
  Future<AbsenStatsModel> fetchAbsenStats() async {
    try {
      var headers = await _getHeaders();

      var now = DateTime.now();
      var startDate = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
      var endDate = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));

      var response = await http.get(
        Uri.parse("${Endpoints.absenStats}?start=$startDate&end=$endDate"),
        headers: headers,
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AbsenStatsModel.fromJson(jsonResponse['data']);
      } else {
        print('fetchAbsenStats: ${response.statusCode} - ${jsonResponse['message']}');
        return AbsenStatsModel(totalAbsen: 0, totalMasuk: 0, totalIzin: 0, sudahAbsenHariIni: false);
      }
    } catch (e) {
      print('fetchAbsenStats error: $e');
      return AbsenStatsModel(totalAbsen: 0, totalMasuk: 0, totalIzin: 0, sudahAbsenHariIni: false);
    }
  }

  // Kirim data check in ke server
  Future<void> checkIn({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      var headers = await _getHeaders();
      var today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var time = DateFormat('HH:mm').format(DateTime.now());

      var response = await http.post(
        Uri.parse(Endpoints.checkIn),
        headers: headers,
        body: jsonEncode({
          "attendance_date": today,
          "check_in": time,
          "check_in_lat": lat,
          "check_in_lng": lng,
          "check_in_address": address,
          "status": "masuk",
        }),
      );

      var jsonResponse = jsonDecode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(jsonResponse['message'] ?? "Gagal Check In");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // Kirim data check out ke server
  Future<void> checkOut({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      var headers = await _getHeaders();
      var today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var time = DateFormat('HH:mm').format(DateTime.now());

      var response = await http.post(
        Uri.parse(Endpoints.checkOut),
        headers: headers,
        body: jsonEncode({
          "attendance_date": today,
          "check_out": time,
          "check_out_lat": lat,
          "check_out_lng": lng,
          "check_out_address": address,
        }),
      );

      var jsonResponse = jsonDecode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(jsonResponse['message'] ?? "Gagal Check Out");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // Ambil riwayat absen (default bulan ini)
  Future<List<AbsenHistoryModel>> fetchHistory({
    String? startDate,
    String? endDate,
  }) async {
    try {
      var headers = await _getHeaders();

      // Kalau tanggal ga diisi, pakai bulan ini
      var now = DateTime.now();
      startDate ??= DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
      endDate ??= DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));

      var response = await http.get(
        Uri.parse("${Endpoints.absenHistory}?start=$startDate&end=$endDate"),
        headers: headers,
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List data = jsonResponse['data'] ?? [];
        return data.map((e) => AbsenHistoryModel.fromJson(e)).toList();
      } else {
        throw Exception(jsonResponse['message'] ?? "Gagal mengambil riwayat");
      }
    } catch (e) {
      print('fetchHistory error: $e');
      return []; // Return kosong biar ga crash
    }
  }

  // Hapus data absen berdasarkan ID
  Future<void> deleteAbsen(int id) async {
    try {
      var headers = await _getHeaders();
      var response = await http.delete(
        Uri.parse(Endpoints.deleteAbsen(id)),
        headers: headers,
      );

      var jsonResponse = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(jsonResponse['message'] ?? "Gagal menghapus data absen");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
}
