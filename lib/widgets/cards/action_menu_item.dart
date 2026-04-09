import 'package:flutter/material.dart';

// Tombol menu aksi di halaman Profile
// (Edit Profil, Ubah Password, Dark Mode, Logout)
class ActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color bgColor;
  final Color textColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const ActionMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.bgColor,
    this.textColor = Colors.black87,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;
    var cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;

    // Kalau dark mode dan warna teks default, ganti jadi putih
    var actualTextColor = (textColor == Colors.black87 && isDark)
        ? Colors.white
        : textColor;

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
            // Icon bulat
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),

            // Judul
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

            // Trailing (panah atau switch)
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
