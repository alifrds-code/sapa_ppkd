import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api/endpoint.dart';
import '../shared_preferences/token_storage.dart';
import '../models/profile_model.dart';
import '../models/absen_today_model.dart';

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
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // 2. Tembak API Absen Hari Ini
  Future<AbsenTodayModel?> fetchAbsenToday() async {
    try {
      var headers = await _getHeaders();
      var response = await http.get(
        Uri.parse(Endpoints.absenToday),
        headers: headers,
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Kalau datanya ada, jadikan model. Kalau belum absen sama sekali (kosong), kembalikan null
        if (jsonResponse['data'] != null) {
          return AbsenTodayModel.fromJson(jsonResponse['data']);
        }
        return null;
      } else {
        throw Exception(
          jsonResponse['message'] ?? "Gagal mengambil data absen",
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
}
