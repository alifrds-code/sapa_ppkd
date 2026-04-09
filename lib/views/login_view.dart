import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'register_view.dart';
import 'main_screen.dart'; // Nanti dibuka kalau file main screen udah ada (Sekarang udah dibuka!)

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _submitLogin() async {
    // Validasi input kosong
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password wajib diisi!")),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final errorMessage = await authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (errorMessage == null) {
      if (!mounted) return;
      // Sukses Login!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Berhasil!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      if (!mounted) return;
      // Gagal Login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF9F9F9);
    final cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final inputFill = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F6FA);
    final inputBorder = isDark ? Colors.white12 : const Color(0xFFDDE3EC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003F87), Color(0xFF0056B3)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.grid_view, size: 40, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        "SAPA PPKD",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Sistem Absensi & Pelatihan",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  "Selamat Datang Kembali!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Masuk ke akun Anda untuk melanjutkan",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 32),

                // --- INPUT EMAIL ---
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF003F87), width: 2),
                    ),
                    prefixIcon: Icon(Icons.email_outlined, color: textSecondary),
                  ),
                ),
                const SizedBox(height: 16),

                // --- INPUT PASSWORD ---
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF003F87), width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // --- TOMBOL LOGIN ---
                InkWell(
                  onTap: authProvider.isLoading ? null : _submitLogin,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003F87), Color(0xFF0056B3)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF003F87).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: authProvider.isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              "LOGIN",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- TOMBOL KE REGISTER ---
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterView(),
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Belum punya akun? ",
                      style: TextStyle(color: textSecondary),
                      children: const [
                        TextSpan(
                          text: "Daftar di sini",
                          style: TextStyle(
                            color: Color(0xFF003F87),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
