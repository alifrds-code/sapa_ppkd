import 'package:flutter/material.dart';

// Nanti file-file ini kita uncomment kalau halamannya udah kita buat
import 'dashboard_view.dart';
// import 'history_view.dart';
// import 'leave_view.dart';
import 'profile_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List halaman yang akan dipanggil sesuai tab yang diklik
  final List<Widget> _pages = [
    const DashboardView(),
    const Center(
      child: Text("2. Halaman Riwayat"),
    ), // Ganti HistoryView() nanti
    const Center(child: Text("3. Halaman Izin")), // Ganti LeaveView() nanti
    const ProfileView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9F9F9,
      ), // Warna background surface dari desain lu
      body: _pages[_selectedIndex],

      // extendBody: true bikin background halaman tembus ke bawah nav bar biar efek melayangnya dapet
      extendBody: true,

      // Custom Bottom Nav Bar Melayang
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95), // Efek glassmorphism tipis
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF003F87,
              ).withOpacity(0.08), // Shadow tipis warna biru
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF0056b3), // Biru Primary
            unselectedItemColor: Colors.grey.shade400,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.event_busy),
                label: 'Izin',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
