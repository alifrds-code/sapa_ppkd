import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/batch_model.dart';
import '../models/training_model.dart';
import '../widgets/common/gradient_button.dart';
import 'main_screen.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _selectedGender;
  BatchModel? _selectedBatch;
  TrainingModel? _selectedTraining;
  File? _imageFile;
  String _base64Image = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() { Provider.of<AuthProvider>(context, listen: false).fetchBatches(); });
  }

  Future<void> _pickImage() async {
    var picker = ImagePicker();
    var image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      var bytes = await File(image.path).readAsBytes();
      setState(() { _imageFile = File(image.path); _base64Image = "data:image/png;base64,${base64Encode(bytes)}"; });
    }
  }

  void _submitRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _selectedGender == null || _selectedBatch == null || _selectedTraining == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap lengkapi semua data wajib!")));
      return;
    }
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password minimal harus 8 karakter!")));
      return;
    }

    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    var errorMessage = await authProvider.register(
      name: _nameController.text, email: _emailController.text, password: _passwordController.text,
      jenisKelamin: _selectedGender!, profilePhotoBase64: _base64Image,
      batchId: _selectedBatch!.id, trainingId: _selectedTraining!.id,
    );

    if (errorMessage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registrasi Berhasil!"), backgroundColor: Colors.green));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    var authProvider = Provider.of<AuthProvider>(context);
    var isDark = Theme.of(context).brightness == Brightness.dark;
    var bgColor = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF9F9F9);
    var cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;
    var textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    var textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    var inputFill = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F6FA);
    var inputBorder = isDark ? Colors.white12 : const Color(0xFFDDE3EC);

    InputDecoration buildInput(String label, {Widget? prefix, Widget? suffix}) {
      return InputDecoration(
        labelText: label, labelStyle: TextStyle(color: textSecondary),
        filled: true, fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF003F87), width: 2)),
        prefixIcon: prefix, suffixIcon: suffix,
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text("Daftar Akun", style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: authProvider.batches.isEmpty && authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Foto Profil
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF003F87), width: 2)),
                      child: CircleAvatar(
                        radius: 48, backgroundColor: isDark ? const Color(0xFF2C2E30) : Colors.grey[200],
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null ? Icon(Icons.camera_alt, size: 32, color: textSecondary) : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text("Ketuk untuk tambah foto", style: TextStyle(fontSize: 12, color: textSecondary))),
                const SizedBox(height: 24),

                TextField(controller: _nameController, style: TextStyle(color: textPrimary), decoration: buildInput("Nama Lengkap", prefix: Icon(Icons.person_outline, color: textSecondary))),
                const SizedBox(height: 14),
                TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, style: TextStyle(color: textPrimary), decoration: buildInput("Email", prefix: Icon(Icons.email_outlined, color: textSecondary))),
                const SizedBox(height: 14),
                TextField(controller: _passwordController, obscureText: _obscurePassword, style: TextStyle(color: textPrimary), decoration: buildInput("Password", prefix: Icon(Icons.lock_outline, color: textSecondary), suffix: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: textSecondary), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
                const SizedBox(height: 20),

                Text("Jenis Kelamin", style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14)),
                const SizedBox(height: 4),
                Row(children: [
                  Radio<String>(value: 'L', groupValue: _selectedGender, activeColor: const Color(0xFF003F87), onChanged: (val) => setState(() => _selectedGender = val)),
                  Text("Laki-laki", style: TextStyle(color: textPrimary)),
                  const SizedBox(width: 16),
                  Radio<String>(value: 'P', groupValue: _selectedGender, activeColor: const Color(0xFF003F87), onChanged: (val) => setState(() => _selectedGender = val)),
                  Text("Perempuan", style: TextStyle(color: textPrimary)),
                ]),
                const SizedBox(height: 14),

                DropdownButtonFormField<BatchModel>(
                  decoration: buildInput("Pilih Batch"), dropdownColor: cardColor,
                  style: TextStyle(color: textPrimary, fontSize: 14), value: _selectedBatch,
                  items: authProvider.batches.map((batch) => DropdownMenuItem(value: batch, child: Text("Batch ${batch.batchKe}"))).toList(),
                  onChanged: (val) => setState(() { _selectedBatch = val; _selectedTraining = null; }),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<TrainingModel>(
                  decoration: buildInput("Pilih Pelatihan"), dropdownColor: cardColor,
                  style: TextStyle(color: textPrimary, fontSize: 14), value: _selectedTraining,
                  items: _selectedBatch == null ? [] : _selectedBatch!.trainings.map((t) => DropdownMenuItem(value: t, child: Text(t.title))).toList(),
                  onChanged: (val) => setState(() => _selectedTraining = val),
                ),
                const SizedBox(height: 28),

                GradientButton(text: "DAFTAR", onTap: _submitRegister, isLoading: authProvider.isLoading),
              ]),
            ),
    );
  }
}
