import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // <-- Tambahan buat format tanggal otomatis

import '../api/endpoint.dart';
import '../shared_preferences/token_storage.dart';
import '../models/profile_model.dart';
import '../models/absen_today_model.dart';
import '../models/absen_stats_model.dart'; // <-- Tambahan model statistik
import '../models/absen_history_model.dart'; // <-- Model riwayat absen

class DashboardService {
  // Fungsi internal untuk nyiapin Header + Token otomatis
  Future<Map<String, String>> _getHeaders() async {
    String? token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', // Ini kunci masuknya!
    };
  }

  // 1. Tembak API Profile
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
      debugPrint('[DashboardService] fetchProfile error: $e');
      // Re-throw agar UI bisa menampilkan error message
      rethrow;
    }
  }

  // 2. Tembak API Absen Hari Ini
  Future<AbsenTodayModel?> fetchAbsenToday() async {
    try {
      var headers = await _getHeaders();
      // Bikin format tanggal YYYY-MM-DD buat hari ini
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      var response = await http.get(
        Uri.parse("${Endpoints.absenToday}?attendance_date=$today"),
        headers: headers,
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Kalau datanya ada, jadikan model. Kalau belum absen sama sekali (kosong), kembalikan null
        if (jsonResponse['data'] != null) {
          return AbsenTodayModel.fromJson(jsonResponse['data']);
        }
        return null;
      } else if (response.statusCode == 404) {
        // 404 = belum ada data absensi hari ini, ini normal → return null
        return null;
      } else {
        throw Exception(
          jsonResponse['message'] ?? "Gagal mengambil data absen",
        );
      }
    } catch (e) {
      // Jangan crash kalau gagal ambil data absen hari ini, cukup return null
      debugPrint('[DashboardService] fetchAbsenToday error: $e');
      return null;
    }
  }

  // 3. Tembak API Update Profile (PUT)
  Future<void> updateProfile({required String name}) async {
    try {
      var headers = await _getHeaders();
      var response = await http.put(
        Uri.parse(
          Endpoints.profile,
        ), // Pakai endpoint yang sama, tapi method-nya PUT
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

  // 4. Tembak API Update Foto Profil
  Future<void> updateProfilePhoto(String base64Image) async {
    try {
      var headers = await _getHeaders();

      // Sesuai API, method-nya POST bukan PUT
      var response = await http.post(
        Uri.parse(Endpoints.updatePhoto),
        headers: headers,
        body: jsonEncode({"profile_photo": base64Image}),
      );

      var jsonResponse = jsonDecode(response.body);

      // Status 200 (OK)
      if (response.statusCode != 200) {
        throw Exception(
          jsonResponse['message'] ?? "Gagal memperbarui foto profil",
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // 5. Tembak API Statistik Absen
  Future<AbsenStatsModel> fetchAbsenStats() async {
    try {
      var headers = await _getHeaders();

      // Kita ambil statistik bulan ini (Dari tanggal 1 sampai hari ini)
      DateTime now = DateTime.now();
      String startDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month, 1));
      // Hari terakhir bulan ini: Set ke bulan+1, hari ke-0
      String endDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month + 1, 0));

      var response = await http.get(
        Uri.parse("${Endpoints.absenStats}?start=$startDate&end=$endDate"),
        headers: headers,
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AbsenStatsModel.fromJson(jsonResponse['data']);
      } else {
        debugPrint('[DashboardService] fetchAbsenStats: ${response.statusCode} - ${jsonResponse['message']}');
        // Return default stats (semua 0) supaya tidak crash
        return AbsenStatsModel(totalAbsen: 0, totalMasuk: 0, totalIzin: 0, sudahAbsenHariIni: false);
      }
    } catch (e) {
      debugPrint('[DashboardService] fetchAbsenStats error: $e');
      // Return default stats supaya tidak crash
      return AbsenStatsModel(totalAbsen: 0, totalMasuk: 0, totalIzin: 0, sudahAbsenHariIni: false);
    }
  }

  // 6. Tembak API Check In
  Future<void> checkIn({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      var headers = await _getHeaders();
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String time = DateFormat('HH:mm').format(DateTime.now());

      var response = await http.post(
        Uri.parse(
          "${Endpoints.baseUrl}/api/absen/check-in",
        ), // Sesuaikan kalau beda
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

  // 7. Tembak API Check Out
  Future<void> checkOut({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      var headers = await _getHeaders();
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String time = DateFormat('HH:mm').format(DateTime.now());

      var response = await http.post(
        Uri.parse(
          "${Endpoints.baseUrl}/api/absen/check-out",
        ), // Sesuaikan kalau beda
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

  // 8. Tembak API Riwayat Absen
  Future<List<AbsenHistoryModel>> fetchHistory({
    String? startDate,
    String? endDate,
  }) async {
    try {
      var headers = await _getHeaders();

      // Default: ambil riwayat bulan ini
      DateTime now = DateTime.now();
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
      debugPrint('[DashboardService] fetchHistory error: $e');
      return []; // Return empty list supaya tidak crash
    }
  }

  // 9. Hapus data absen berdasarkan ID (Bonus)
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
