import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/dashboard_service.dart';
import '../models/profile_model.dart';
import '../models/absen_today_model.dart';
import '../models/absen_stats_model.dart';
import 'absen_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardService _dashboardService = DashboardService();

  // Variabel untuk menampung Data API
  late Future<ProfileModel> _profileFuture;
  late Future<AbsenTodayModel?> _absenTodayFuture;
  late Future<AbsenStatsModel> _absenStatsFuture;

  // Variabel Jam & Lokasi
  Timer? _timer;
  String _timeString = "";
  String _dateString = "";

  bool _isLoadingLocation = true;
  Position? _currentPosition;
  String _currentAddress = "Mencari lokasi...";

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _getCurrentLocation();

    // Bangunkan kamus bahasa Indonesia, baru nyalain jam
    initializeDateFormatting('id_ID', null).then((_) {
      _startClock();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Matikan jam
    super.dispose();
  }

  void _loadAllData() {
    setState(() {
      _profileFuture = _dashboardService.fetchProfile();
      _absenTodayFuture = _dashboardService.fetchAbsenToday();
      _absenStatsFuture = _dashboardService.fetchAbsenStats();
    });
  }

  // --- LOGIKA JAM LIVE ---
  void _startClock() {
    setState(() {
      _timeString = DateFormat('HH:mm:ss').format(DateTime.now());
      _dateString = DateFormat(
        'EEEE, dd MMMM yyyy',
        'id_ID',
      ).format(DateTime.now());
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {
          _timeString = DateFormat('HH:mm:ss').format(DateTime.now());
          _dateString = DateFormat(
            'EEEE, dd MMMM yyyy',
            'id_ID',
          ).format(DateTime.now());
        });
      }
    });
  }

  // --- LOGIKA GPS & LOKASI ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("GPS tidak aktif. Nyalakan GPS.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Izin lokasi ditolak.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Izin lokasi diblokir permanen.");
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentAddress = "${place.street}, ${place.subAdministrativeArea}";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = e.toString().replaceAll("Exception: ", "");
          _isLoadingLocation = false;
        });
      }
    }
  }

  // --- NAVIGASI KE HALAMAN ABSEN ---
  void _navigateToAbsen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AbsenView()),
    );
    // Refresh data setelah kembali dari AbsenView
    if (result == true || result == null) {
      _loadAllData();
    }
  }

  // --- GREETING DINAMIS ---
  String _getGreeting(String firstName) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (hour >= 12 && hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour >= 15 && hour < 19) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }
    return '$greeting, $firstName! 👋';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF9F9F9);
    final cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadAllData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: 120,
            ),
            child: FutureBuilder<ProfileModel>(
              future: _profileFuture,
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (profileSnapshot.hasError) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            "Gagal memuat data",
                            style: TextStyle(color: textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Periksa koneksi internet Anda",
                            style: TextStyle(color: textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadAllData,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text("Coba Lagi"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003F87),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final user = profileSnapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- CUSTOM HEADER (SAPA PPKD & FOTO PROFIL) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.grid_view,
                              color: Color(0xFF003F87),
                            ),
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
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0056B3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: user.profilePhotoUrl != null
                                ? NetworkImage(user.profilePhotoUrl!)
                                : null,
                            child: user.profilePhotoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- GREETING SECTION ---
                    Text(
                      "PUSAT PELATIHAN KERJA DAERAH",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGreeting(user.name.split(' ').first),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1C1C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Batch ${user.batchKe ?? '-'} - ${user.trainingTitle ?? '-'}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- BENTO BOX 1: JAM & TOMBOL ABSEN ---
                    FutureBuilder<AbsenTodayModel?>(
                      future: _absenTodayFuture,
                      builder: (context, absenSnapshot) {
                        if (absenSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final absenToday = absenSnapshot.data;

                        // Logika Penentuan Status (isCheckIn tidak dipakai lagi, tombol navigasi ke AbsenView)
                        bool isCheckOut =
                            absenToday != null &&
                            (absenToday.checkInTime ?? "").isNotEmpty &&
                            (absenToday.checkOutTime ?? "").isEmpty;
                        bool isDone =
                            absenToday != null &&
                            (absenToday.checkInTime ?? "").isNotEmpty &&
                            (absenToday.checkOutTime ?? "").isNotEmpty;

                        // Variabel UI
                        String statusText = "Belum Absen";
                        Color statusBgColor = const Color(0xFFFFDAD6);
                        Color statusTextColor = const Color(0xFF93000A);
                        Color statusDotColor = const Color(0xFFBA1A1A);

                        String buttonText = "CHECK IN";
                        IconData buttonIcon = Icons.login;
                        List<Color> buttonGradient = [
                          const Color(0xFF003F87),
                          const Color(0xFF0056B3),
                        ];

                        if (isCheckOut) {
                          statusText = "Sedang Bekerja";
                          statusBgColor = Colors.orange.shade100;
                          statusTextColor = Colors.orange.shade900;
                          statusDotColor = Colors.orange.shade700;

                          buttonText = "CHECK OUT";
                          buttonIcon = Icons.logout;
                          buttonGradient = [
                            Colors.orange.shade700,
                            Colors.orange.shade900,
                          ];
                        } else if (isDone) {
                          statusText = "Selesai Absen";
                          statusBgColor = Colors.green.shade100;
                          statusTextColor = Colors.green.shade900;
                          statusDotColor = Colors.green.shade700;

                          buttonText = "SELESAI";
                          buttonIcon = Icons.check_circle;
                          buttonGradient = [
                            Colors.grey.shade500,
                            Colors.grey.shade600,
                          ];
                        }

                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
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
                                  // Badge Status
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: statusDotColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          statusText
                                              .toUpperCase(), // Tambahin .toUpperCase() di sini
                                          style: TextStyle(
                                            color: statusTextColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                            // Hapus baris uppercase: true yang error tadi
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Jam Raksasa
                                  Text(
                                    _timeString.isEmpty
                                        ? "--:--:--"
                                        : _timeString,
                                    style: TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF003F87),
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Tombol Absen → Navigasi ke AbsenView
                                  InkWell(
                                    onTap: _navigateToAbsen,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: buttonGradient,
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: buttonGradient[0]
                                                .withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            buttonIcon,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            buttonText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Teks Lokasi di bawah tombol
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Color(0xFF727784),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _isLoadingLocation
                                              ? 'Mencari lokasi...'
                                              : _currentAddress,
                                          style: const TextStyle(
                                            color: Color(0xFF727784),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // --- BENTO BOX 2: MAP / LOKASI DETAIL ---
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0FE),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Map preview image
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    child: _currentPosition != null
                                        ? Image.network(
                                            'https://maps.googleapis.com/maps/api/staticmap?center=${_currentPosition!.latitude},${_currentPosition!.longitude}&zoom=15&size=600x200&maptype=roadmap&markers=color:blue%7C${_currentPosition!.latitude},${_currentPosition!.longitude}&key=YOUR_API_KEY',
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 120,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isDark
                                                      ? [const Color(0xFF1E3A5F), const Color(0xFF0D253F)]
                                                      : [const Color(0xFFBBD0FF), const Color(0xFFE8F0FE)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Icon(Icons.map, size: 60, color: isDark ? Colors.white10 : Colors.white38),
                                                  Icon(Icons.location_on, size: 32, color: const Color(0xFF003F87).withOpacity(0.7)),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Container(
                                            height: 120,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isDark
                                                    ? [const Color(0xFF1E3A5F), const Color(0xFF0D253F)]
                                                    : [const Color(0xFFBBD0FF), const Color(0xFFE8F0FE)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(Icons.map, size: 60, color: isDark ? Colors.white10 : Colors.white38),
                                                _isLoadingLocation
                                                    ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003F87)))
                                                    : Icon(Icons.location_on, size: 32, color: const Color(0xFF003F87).withOpacity(0.7)),
                                              ],
                                            ),
                                          ),
                                  ),
                                  // Info lokasi
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.location_on, color: Color(0xFF003F87), size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "LOKASI SAYA",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: textSecondary,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _isLoadingLocation ? "Mencari lokasi..." : _currentAddress,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimary,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- RINGKASAN KEHADIRAN (STATISTIK) ---
                    Text(
                      "RINGKASAN KEHADIRAN",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<AbsenStatsModel>(
                      future: _absenStatsFuture,
                      builder: (context, statsSnapshot) {
                        if (statsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (statsSnapshot.hasError) {
                          return const Text("Gagal memuat statistik");
                        }

                        final stats = statsSnapshot.data!;

                        return Row(
                          children: [
                            // Card Hadir
                            _buildStatCard(
                              title: "Hadir",
                              count: stats.totalMasuk.toString(),
                              icon: Icons.check_circle,
                              iconColor: const Color(0xFF003F87), // Biru
                              bgColor: const Color(0xFFE8F0FE),
                            ),
                            const SizedBox(width: 16),
                            // Card Izin
                            _buildStatCard(
                              title: "Izin",
                              count: stats.totalIzin.toString(),
                              icon: Icons.event_note,
                              iconColor: const Color(
                                0xFF722B00,
                              ), // Tertiary HTML
                              bgColor: const Color(0xFFFFDBCC),
                            ),
                            const SizedBox(width: 16),
                            // Card Alpa
                            _buildStatCard(
                              title: "Alpa",
                              count: "0",
                              icon: Icons.cancel,
                              iconColor: const Color(0xFFBA1A1A), // Red Error
                              bgColor: const Color(0xFFFFDAD6),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // --- INFO & TIPS SECTION ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E3A5F), const Color(0xFF2C2E30)]
                              : [const Color(0xFFE8F0FE), const Color(0xFFF3F6FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003F87).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.lightbulb_outline, color: Color(0xFF003F87), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "INFORMASI PENTING",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTipItem("Pastikan GPS aktif sebelum check-in", Icons.gps_fixed, textPrimary, textSecondary),
                          const SizedBox(height: 10),
                          _buildTipItem("Check-in paling lambat pukul 08:00 WIB", Icons.access_time, textPrimary, textSecondary),
                          const SizedBox(height: 10),
                          _buildTipItem("Ajukan izin sebelum hari yang dimaksud", Icons.event_available, textPrimary, textSecondary),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Widget Pembantu buat Kotak Statistik Bento
  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              count,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF003F87)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
          ),
        ),
      ],
    );
  }
}
