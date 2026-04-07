import 'package:flutter/material.dart';
import '../models/batch_model.dart';
import '../services/auth_services.dart'; // <-- Typo nama file udah dibenerin di sini
import '../shared_preferences/token_storage.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // ----- STATE VARIABEL -----
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<BatchModel> _batches = [];
  List<BatchModel> get batches => _batches;

  // ----- FUNGSI 1: Ambil Data Dropdown Batch & Training -----
  Future<void> fetchBatches() async {
    try {
      _isLoading = true;
      notifyListeners(); // Kasih tau UI buat nampilin loading

      _batches = await _authService.getBatches();
    } catch (e) {
      print("Error fetch batches: $e");
      // Kita biarin kosong kalau error, nanti UI bisa nanganin
    } finally {
      _isLoading = false;
      notifyListeners(); // Kasih tau UI loading selesai
    }
  }

  // ----- FUNGSI 2: Proses Registrasi -----
  // Mengembalikan String. Kalau null berarti sukses, kalau ada isi berarti pesan error.
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
      notifyListeners(); // Tombol register jadi muter-muter

      // Nembak API lewat AuthService
      final responseData = await _authService.register(
        name: name,
        email: email,
        password: password,
        jenisKelamin: jenisKelamin,
        profilePhotoBase64: profilePhotoBase64,
        batchId: batchId,
        trainingId: trainingId,
      );

      // Kalau sukses, kita ambil token dari response
      final token = responseData['token'];
      if (token != null) {
        await TokenStorage.saveToken(token); // Simpan token ke HP
      }

      return null; // Null berarti SUKSES, tidak ada error
    } catch (e) {
      // Potong kata "Exception: " biar yang muncul cuma pesannya aja
      return e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners(); // Matiin efek muter-muter
    }
  }

  // ----- FUNGSI 3: Proses Login -----
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners(); // Muter-muter tombol login

      final responseData = await _authService.login(
        email: email,
        password: password,
      );

      final token = responseData['token'];
      if (token != null) {
        await TokenStorage.saveToken(token); // Simpan token ke HP
      }

      return null; // Null berarti SUKSES
    } catch (e) {
      // Potong kata "Exception: " biar UI-nya bersih
      return e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners(); // Matiin muter-muter
    }
  }
}
