import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/batch_model.dart';
import '../models/training_model.dart';
import 'main_screen.dart'; // <-- Tambahan import Main Screen

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variabel baru buat ngatur logo mata password
  bool _obscurePassword = true;

  String? _selectedGender; // 'L' atau 'P'
  BatchModel? _selectedBatch;
  TrainingModel? _selectedTraining;

  File? _imageFile;
  String _base64Image = "";

  @override
  void initState() {
    super.initState();
    // Saat halaman dibuka, otomatis panggil API untuk ambil data Batch & Training
    Future.microtask(() {
      Provider.of<AuthProvider>(context, listen: false).fetchBatches();
    });
  }

  // Fungsi untuk buka galeri dan ubah foto jadi Base64
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      String base64Data = base64Encode(bytes);

      setState(() {
        _imageFile = File(image.path);
        // Sesuai format API di dokumen, harus ada awalan data:image/png;base64,
        _base64Image = "data:image/png;base64,$base64Data";
      });
    }
  }

  // Fungsi untuk proses tombol Daftar
  void _submitRegister() async {
    // 1. Validasi sederhana biar user nggak ngirim data kosong
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedGender == null ||
        _selectedBatch == null ||
        _selectedTraining == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap lengkapi semua data wajib!")),
      );
      return;
    }

    // --- TAMBAHAN: VALIDASI PASSWORD ---
    // Ngecek apakah password kurang dari 8 karakter
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal harus 8 karakter!")),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 2. Tembak API lewat provider
    final errorMessage = await authProvider.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      jenisKelamin: _selectedGender!,
      profilePhotoBase64: _base64Image, // Kosong "" kalau nggak milih foto
      batchId: _selectedBatch!.id,
      trainingId: _selectedTraining!.id,
    );

    // 3. Cek hasil dari server
    if (errorMessage == null) {
      // Sukses!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registrasi Berhasil!"),
          backgroundColor: Colors.green,
        ),
      );

      // Nanti diarahkan ke MainScreen. Sementara kita print dulu
      print("Token tersimpan, siap ke MainScreen!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // Gagal! Tampilkan pesan error dari server
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil state provider buat ngecek loading & data batch
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Akun PPKD"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: authProvider.batches.isEmpty && authProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Muter-muter awal pas ambil Batch
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- FOTO PROFIL ---
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : null,
                        child: _imageFile == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(child: Text("Ketuk untuk tambah foto")),
                  const SizedBox(height: 30),

                  // --- INPUT TEKS ---
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nama Lengkap",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- TAMBAHAN: INPUT PASSWORD DENGAN LOGO MATA ---
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // Pakai variabel state
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          // Ganti icon berdasarkan status _obscurePassword
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Ubah status tertutup/terbuka saat diklik
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- RADIO BUTTON JENIS KELAMIN ---
                  const Text(
                    "Jenis Kelamin",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'L',
                        groupValue: _selectedGender,
                        onChanged: (val) =>
                            setState(() => _selectedGender = val),
                      ),
                      const Text("Laki-laki"),
                      const SizedBox(width: 20),
                      Radio<String>(
                        value: 'P',
                        groupValue: _selectedGender,
                        onChanged: (val) =>
                            setState(() => _selectedGender = val),
                      ),
                      const Text("Perempuan"),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // --- DROPDOWN BATCH ---
                  DropdownButtonFormField<BatchModel>(
                    decoration: const InputDecoration(
                      labelText: "Pilih Batch",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedBatch,
                    items: authProvider.batches.map((batch) {
                      return DropdownMenuItem(
                        value: batch,
                        child: Text("Batch ${batch.batchKe}"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedBatch = val;
                        // Kalau batch diganti, reset pilihan trainingnya
                        _selectedTraining = null;
                      });
                    },
                  ),
                  const SizedBox(height: 15),

                  // --- DROPDOWN TRAINING (Muncul Otomatis Sesuai Batch) ---
                  DropdownButtonFormField<TrainingModel>(
                    decoration: const InputDecoration(
                      labelText: "Pilih Pelatihan",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedTraining,
                    items: _selectedBatch == null
                        ? [] // Kosong kalau belum pilih batch
                        : _selectedBatch!.trainings.map((training) {
                            return DropdownMenuItem(
                              value: training,
                              child: Text(training.title),
                            );
                          }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTraining = val;
                      });
                    },
                  ),
                  const SizedBox(height: 30),

                  // --- TOMBOL DAFTAR ---
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : _submitRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "DAFTAR",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
