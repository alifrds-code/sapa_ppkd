import 'package:flutter/material.dart';
import '../models/batch_model.dart';
import '../services/auth_services.dart';
import '../shared_preferences/token_storage.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // Loading state buat nampilin spinner di UI
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Data batch buat dropdown di halaman register
  List<BatchModel> _batches = [];
  List<BatchModel> get batches => _batches;

  // Ambil data batch & training dari API buat dropdown
  Future<void> fetchBatches() async {
    try {
      _isLoading = true;
      notifyListeners();

      _batches = await _authService.getBatches();
    } catch (e) {
      print("Error fetch batches: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Proses registrasi — return null kalau sukses, return pesan error kalau gagal
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String jenisKelamin,
    required String profilePhotoBase64,
    required int batchId,
    required int trainingId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      var responseData = await _authService.register(
        name: name,
        email: email,
        password: password,
        jenisKelamin: jenisKelamin,
        profilePhotoBase64: profilePhotoBase64,
        batchId: batchId,
        trainingId: trainingId,
      );

      // Simpan token kalau ada
      var token = responseData['token'];
      if (token != null) {
        await TokenStorage.saveToken(token);
      }

      return null; // null = sukses
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Proses login — return null kalau sukses, return pesan error kalau gagal
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      var responseData = await _authService.login(
        email: email,
        password: password,
      );

      // Simpan token kalau ada
      var token = responseData['token'];
      if (token != null) {
        await TokenStorage.saveToken(token);
      }

      return null; // null = sukses
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
