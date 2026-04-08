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

  // --- LOGIKA TOMBOL ABSEN ---
  void _handleAbsen(AbsenTodayModel? absenToday) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tunggu lokasi ditemukan!")));
      return;
    }

    bool isCheckIn =
        absenToday == null || (absenToday.checkInTime ?? "").isEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (isCheckIn) {
        await _dashboardService.checkIn(
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          address: _currentAddress,
        );
      } else {
        await _dashboardService.checkOut(
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          address: _currentAddress,
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCheckIn ? "Berhasil Check In!" : "Berhasil Check Out!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadAllData(); // Refresh API
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9F9F9,
      ), // Warna background dari Tailwind lu
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
                  return Center(child: Text("Error: ${profileSnapshot.error}"));
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
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Selamat Pagi, ${user.name.split(' ').first}!",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1C1C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Batch ${user.batchKe ?? '-'} - ${user.trainingTitle ?? '-'}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
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

                        // Logika Penentuan Tombol & Status
                        bool isCheckIn =
                            absenToday == null ||
                            (absenToday.checkInTime ?? "").isEmpty;
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
                                color: Colors.white,
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
                                    style: const TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF003F87),
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Tombol Absen Gradient
                                  InkWell(
                                    onTap: isDone
                                        ? null
                                        : () => _handleAbsen(absenToday),
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
                                              ? "Mencari lokasi..."
                                              : "PPKD Jakarta",
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
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE8F0FE,
                                ), // Warna biru soft sebagai ganti gambar peta
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          "LOKASI SAYA",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF003F87),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0056B3),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.my_location,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Titik Kordinat Saat Ini",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1C1C),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isLoadingLocation
                                              ? "Mengambil data satelit..."
                                              : _currentAddress,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                            height: 1.5,
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
                        color: Colors.grey.shade600,
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
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
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1C1C),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
