import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/dashboard_service.dart';
import '../models/profile_model.dart';
import '../shared_preferences/token_storage.dart';
import 'login_view.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final DashboardService _dashboardService = DashboardService();

  // TAMBAHAN: Variabel buat nampung masa depan (Future) API Profil biar gak dispam
  late Future<ProfileModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    // Panggil API cuma 1x pas halaman pertama kali dibuka
    _profileFuture = _dashboardService.fetchProfile();
  }

  // Fungsi buat Refresh API setelah ganti nama atau foto
  void _refreshProfileData() {
    setState(() {
      _profileFuture = _dashboardService.fetchProfile();
    });
  }

  // Fungsi buat Logout (Hapus Token -> Lempar ke Login)
  void _logout() async {
    // 1. Munculin dialog konfirmasi biar nggak kepencet
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // 2. Kalau user klik "Logout", hapus token dan pindah halaman
    if (confirm == true) {
      await TokenStorage.deleteToken();
      if (!mounted) return;

      // pushAndRemoveUntil biar user nggak bisa klik tombol "Back" ke aplikasi
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF9F9F9);
    final cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      // Top App Bar
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Icon(Icons.grid_view, size: 22, color: const Color(0xFF003F87)),
            const SizedBox(width: 8),
            const Text(
              "SAPA PPKD",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF003F87),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),

      // FutureBuilder buat narik API Profile secara otomatis pas halaman dibuka
      body: FutureBuilder<ProfileModel>(
        future:
            _profileFuture, // PERUBAHAN: Pakai variabel Future yang udah disiapin
        builder: (context, snapshot) {
          // 1. Kalau lagi loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Kalau error/gagal narik data
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gagal memuat profil:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          // 3. Kalau sukses, masukin datanya ke variabel user
          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            // Tambahin padding bawah biar nggak ketutup Bottom Nav Bar melayang
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- HEADER PROFIL (FOTO & NAMA) ---
                  GestureDetector(
                    // Logika nge-zoom gambar kalau diklik ala Instagram
                    onTap: () {
                      if (user.profilePhotoUrl != null) {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(10),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                InteractiveViewer(
                                  child: Image.network(user.profilePhotoUrl!),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 130,
                      height: 130,
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF003F87), Color(0xFFBBD0FF)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: user.profilePhotoUrl != null
                            ? NetworkImage(user.profilePhotoUrl!)
                            : null,
                        child: user.profilePhotoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A1C1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "BATCH ${user.batchKe ?? '-'} | PPKD",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF5B9CF6) : const Color(0xFF003F87),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- BENTO BOX: INFORMASI DATA DIRI ---
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow("Email", user.email, Icons.email, isDark: isDark),
                        Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF3F3F3)),
                        _buildInfoRow(
                          "Jenis Kelamin",
                          user.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan',
                          Icons.person_outline,
                          isDark: isDark,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF3F3F3)),
                        _buildInfoRow(
                          "Pelatihan",
                          user.trainingTitle ?? '-',
                          Icons.school,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- MENU PENGATURAN ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "PENGATURAN AKUN",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tombol Edit Profil
                  _buildActionMenu(
                    icon: Icons.person_outline,
                    title: "Edit Profil",
                    iconColor: const Color(0xFF003F87),
                    bgColor: const Color(0xFFD7E2FF),
                    isDark: isDark,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileView(
                            currentUser: user,
                          ),
                        ),
                      );
                      if (result == true) {
                        _refreshProfileData();
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tombol Ubah Password
                  _buildActionMenu(
                    icon: Icons.lock_reset,
                    title: "Ubah Password",
                    iconColor: const Color(0xFF003F87),
                    bgColor: const Color(0xFFD7E2FF),
                    isDark: isDark,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Fitur Ubah Password segera hadir"),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tombol Dark Mode (Bonus 5.3)
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildActionMenu(
                        icon: themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        title: themeProvider.isDarkMode
                            ? 'Mode Terang'
                            : 'Mode Gelap',
                        iconColor: themeProvider.isDarkMode
                            ? Colors.amber.shade700
                            : const Color(0xFF003F87),
                        bgColor: themeProvider.isDarkMode
                            ? Colors.amber.shade50
                            : const Color(0xFFD7E2FF),
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (_) => themeProvider.toggleTheme(),
                          activeColor: const Color(0xFF003F87),
                        ),
                        isDark: isDark,
                        onTap: () => themeProvider.toggleTheme(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tombol Logout (Merah)
                  _buildActionMenu(
                    icon: Icons.logout,
                    title: "Logout",
                    iconColor: Colors.red.shade700,
                    bgColor: Colors.red.shade50,
                    textColor: Colors.red.shade700,
                    onTap: _logout,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER BUAT BIKIN UI LEBIH RAPI ---

  // Baris Info Data Diri
  Widget _buildInfoRow(String label, String value, IconData icon, {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade500 : Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 200,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Icon(icon, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  // Tombol Menu Aksi
  Widget _buildActionMenu({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color bgColor,
    Color textColor = Colors.black87,
    Widget? trailing,
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    final cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;
    // Adjust text color for dark mode
    final actualTextColor = (textColor == Colors.black87 && isDark) ? Colors.white : textColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: actualTextColor,
                ),
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
