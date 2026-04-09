import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/endpoint.dart';
import '../models/batch_model.dart';

class AuthService {
  // Ambil data batch & training dari server buat dropdown register
  Future<List<BatchModel>> getBatches() async {
    try {
      var response = await http.get(Uri.parse(Endpoints.batches));

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List data = jsonResponse['data'];
        return data.map((e) => BatchModel.fromJson(e)).toList();
      } else {
        throw Exception("Gagal mengambil data Batch dari server");
      }
    } catch (e) {
      throw Exception("Terjadi kesalahan jaringan: $e");
    }
  }

  // Kirim data registrasi ke server
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
          'Accept': 'application/json',
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonResponse['data'];
      } else {
        var errorMessage = jsonResponse['message'] ?? "Registrasi gagal";
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // Kirim data login ke server
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

      if (response.statusCode == 200) {
        return jsonResponse['data'];
      } else {
        throw Exception("Email atau password salah.");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
}
