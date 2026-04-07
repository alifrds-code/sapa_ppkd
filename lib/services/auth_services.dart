import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/endpoint.dart';
import '../models/batch_model.dart';

class AuthService {
  // Fungsi 1: Ngambil data Batch & Training buat Dropdown
  Future<List<BatchModel>> getBatches() async {
    try {
      var response = await http.get(Uri.parse(Endpoints.batches));

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List data = jsonResponse['data'];

        // Ubah data JSON mentah jadi bentuk BatchModel yang rapi
        return data.map((e) => BatchModel.fromJson(e)).toList();
      } else {
        throw Exception("Gagal mengambil data Batch dari server");
      }
    } catch (e) {
      throw Exception("Terjadi kesalahan jaringan: $e");
    }
  }

  // Fungsi 2: Kirim data Register ke server
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String jenisKelamin,
    required String profilePhotoBase64,
    required int batchId,
    required int trainingId,
  }) async {
    try {
      var response = await http.post(
        Uri.parse(Endpoints.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept':
              'application/json', // Biar server tau kita minta balasan format JSON
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "jenis_kelamin": jenisKelamin,
          "profile_photo": profilePhotoBase64,
          "batch_id": batchId,
          "training_id": trainingId,
        }),
      );

      var jsonResponse = jsonDecode(response.body);

      // Status 200 atau 201 itu artinya sukses di REST API
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonResponse['data']; // Balikin data token & info user
      } else {
        // Nangkep pesan error dari server (Misal: "Email sudah terdaftar")
        String errorMessage = jsonResponse['message'] ?? "Registrasi gagal";
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Bersihin teks "Exception:" biar yang muncul di layar HP cuma pesan error-nya aja
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // Fungsi 3: Proses Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      var response = await http.post(
        Uri.parse(Endpoints.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      var jsonResponse = jsonDecode(response.body);

      // Status 200 berarti sukses
      if (response.statusCode == 200) {
        return jsonResponse['data'];
      } else {
        // --- PERUBAHAN DI SINI ---
        // Kita abaikan pesan dari server, dan paksa keluarin pesan seragam
        throw Exception("Email atau password salah.");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
}
