import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/dashboard_service.dart';
import '../models/profile_model.dart';
import '../shared_preferences/token_storage.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/cards/action_menu_item.dart';
import 'login_view.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final DashboardService _dashboardService = DashboardService();
  late Future<ProfileModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _dashboardService.fetchProfile();
  }

  void _refreshProfileData() {
    setState(() { _profileFuture = _dashboardService.fetchProfile(); });
  }

  void _logout() async {
    var confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TokenStorage.deleteToken();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginView()), (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;
    var bgColor = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF9F9F9);
    var cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor, elevation: 0, scrolledUnderElevation: 0,
        title: const AppLogo(),
      ),
      body: FutureBuilder<ProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Gagal memuat profil:\n${snapshot.error}", textAlign: TextAlign.center));

          var user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Foto profil
                  GestureDetector(
                    onTap: () {
                      if (user.profilePhotoUrl != null) {
                        showDialog(context: context, builder: (context) => Dialog(
                          backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(10),
                          child: Stack(alignment: Alignment.topRight, children: [
                            InteractiveViewer(child: Image.network(user.profilePhotoUrl!)),
                            IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
                          ]),
                        ));
                      }
                    },
                    child: Container(
                      width: 130, height: 130, padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF003F87), Color(0xFFBBD0FF)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) : null,
                        child: user.profilePhotoUrl == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(user.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1C1C))),
                  const SizedBox(height: 4),
                  Text("BATCH ${user.batchKe ?? '-'} | PPKD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF5B9CF6) : const Color(0xFF003F87), letterSpacing: 1.2)),
                  const SizedBox(height: 30),

                  // Info data diri
                  Container(
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]),
                    child: Column(children: [
                      _buildInfoRow("Email", user.email, Icons.email, isDark: isDark),
                      Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF3F3F3)),
                      _buildInfoRow("Jenis Kelamin", user.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan', Icons.person_outline, isDark: isDark),
                      Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF3F3F3)),
                      _buildInfoRow("Pelatihan", user.trainingTitle ?? '-', Icons.school, isDark: isDark),
                    ]),
                  ),
                  const SizedBox(height: 30),

                  Align(alignment: Alignment.centerLeft, child: Text("PENGATURAN AKUN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey.shade500))),
                  const SizedBox(height: 10),

                  // Tombol Edit Profil
                  ActionMenuItem(
                    icon: Icons.person_outline, title: "Edit Profil",
                    iconColor: const Color(0xFF003F87), bgColor: const Color(0xFFD7E2FF),
                    onTap: () async {
                      var result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileView(currentUser: user)));
                      if (result == true) _refreshProfileData();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tombol Ubah Password
                  ActionMenuItem(
                    icon: Icons.lock_reset, title: "Ubah Password",
                    iconColor: const Color(0xFF003F87), bgColor: const Color(0xFFD7E2FF),
                    onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Ubah Password segera hadir"))); },
                  ),
                  const SizedBox(height: 12),

                  // Tombol Dark Mode
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return ActionMenuItem(
                        icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        title: themeProvider.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
                        iconColor: themeProvider.isDarkMode ? Colors.amber.shade700 : const Color(0xFF003F87),
                        bgColor: themeProvider.isDarkMode ? Colors.amber.shade50 : const Color(0xFFD7E2FF),
                        trailing: Switch(value: themeProvider.isDarkMode, onChanged: (_) => themeProvider.toggleTheme(), activeColor: const Color(0xFF003F87)),
                        onTap: () => themeProvider.toggleTheme(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tombol Logout
                  ActionMenuItem(
                    icon: Icons.logout, title: "Logout",
                    iconColor: Colors.red.shade700, bgColor: Colors.red.shade50,
                    textColor: Colors.red.shade700, onTap: _logout,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade500 : Colors.grey, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          SizedBox(width: 200, child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis)),
        ]),
        Icon(icon, color: Colors.grey.shade400, size: 20),
      ]),
    );
  }
}
