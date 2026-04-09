import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../models/profile_model.dart';
import '../services/dashboard_service.dart';
import '../widgets/common/gradient_button.dart';

class EditProfileView extends StatefulWidget {
  final ProfileModel currentUser;

  const EditProfileView({super.key, required this.currentUser});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final DashboardService _dashboardService = DashboardService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  bool _isLoading = false;
  File? _imageFile;
  String _base64Image = "";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _emailController = TextEditingController(text: widget.currentUser.email);
  }

  Future<void> _pickImage() async {
    var picker = ImagePicker();
    var image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      var bytes = await File(image.path).readAsBytes();
      setState(() { _imageFile = File(image.path); _base64Image = "data:image/png;base64,${base64Encode(bytes)}"; });
    }
  }

  void _submitUpdate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama tidak boleh kosong!")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _dashboardService.updateProfile(name: _nameController.text);
      if (_base64Image.isNotEmpty) await _dashboardService.updateProfilePhoto(_base64Image);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui!"), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;
    var bgColor = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF9F9F9);
    var textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    var textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    var inputFill = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F6FA);
    var inputBorder = isDark ? Colors.white12 : const Color(0xFFDDE3EC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text("Edit Profil", style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Foto profil
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(alignment: Alignment.bottomRight, children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? const Color(0xFF2C2E30) : const Color(0xFFBBD0FF)),
                  child: ClipOval(
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : (widget.currentUser.profilePhotoUrl != null
                            ? Image.network(widget.currentUser.profilePhotoUrl!, fit: BoxFit.cover)
                            : Icon(Icons.person, size: 60, color: isDark ? Colors.grey : const Color(0xFF003F87))),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF003F87), shape: BoxShape.circle, border: Border.all(color: bgColor, width: 2)),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text("Ketuk untuk ubah foto", style: TextStyle(fontSize: 12, color: textSecondary))),
          const SizedBox(height: 28),

          // Email (ga bisa diedit)
          Text("Email", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController, enabled: false,
            style: TextStyle(color: textSecondary),
            decoration: InputDecoration(
              filled: true, fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade200,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder)),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder)),
              prefixIcon: Icon(Icons.email_outlined, color: textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Nama
          Text("Nama Lengkap", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              filled: true, fillColor: inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inputBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF003F87), width: 2)),
              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF003F87)),
            ),
          ),
          const SizedBox(height: 36),

          // Tombol Simpan
          GradientButton(text: "SIMPAN PERUBAHAN", onTap: _submitUpdate, isLoading: _isLoading),
        ]),
      ),
    );
  }
}
