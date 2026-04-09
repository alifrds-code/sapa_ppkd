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
import '../widgets/common/app_logo.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/common/location_card.dart';
import '../widgets/cards/stat_card.dart';
import '../widgets/cards/tips_card.dart';
import 'absen_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardService _dashboardService = DashboardService();

  // Data dari API
  late Future<ProfileModel> _profileFuture;
  late Future<AbsenTodayModel?> _absenTodayFuture;
  late Future<AbsenStatsModel> _absenStatsFuture;

  // Buat jam live dan lokasi
  Timer? _timer;
  String _timeString = "";

  bool _isLoadingLocation = true;
  Position? _currentPosition;
  String _currentAddress = "Mencari lokasi...";

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _getCurrentLocation();

    initializeDateFormatting('id_ID', null).then((_) {
      _startClock();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Panggil semua API sekaligus
  void _loadAllData() {
    setState(() {
      _profileFuture = _dashboardService.fetchProfile();
      _absenTodayFuture = _dashboardService.fetchAbsenToday();
      _absenStatsFuture = _dashboardService.fetchAbsenStats();
    });
  }

  // Jalanin jam yang update tiap detik
  void _startClock() {
    setState(() {
      _timeString = DateFormat('HH:mm:ss').format(DateTime.now());
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {
          _timeString = DateFormat('HH:mm:ss').format(DateTime.now());
        });
      }
    });
  }

  // Ambil lokasi GPS
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("GPS tidak aktif. Nyalakan GPS.");

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Izin lokasi ditolak.");
      }
      if (permission == LocationPermission.deniedForever) throw Exception("Izin lokasi diblokir permanen.");

      var position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      var placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      var place = placemarks[0];

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

  // Buka halaman absen, terus refresh data pas balik
  void _navigateToAbsen() async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AbsenView()),
    );
    if (result == true || result == null) _loadAllData();
  }

  // Salam sesuai jam
  String _getGreeting(String firstName) {
    var hour = DateTime.now().hour;
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
    var isDark = Theme.of(context).brightness == Brightness.dark;
    var bgColor = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF9F9F9);
    var cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;
    var textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    var textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadAllData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
            child: FutureBuilder<ProfileModel>(
              future: _profileFuture,
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
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
                          Text("Gagal memuat data", style: TextStyle(color: textSecondary, fontSize: 14)),
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

                var user = profileSnapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppLogo(),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0056B3), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) : null,
                            child: user.profilePhotoUrl == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Greeting
                    Text("PUSAT PELATIHAN KERJA DAERAH", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: textSecondary)),
                    const SizedBox(height: 4),
                    Text(_getGreeting(user.name.split(' ').first), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text("Batch ${user.batchKe ?? '-'} - ${user.trainingTitle ?? '-'}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary)),
                    const SizedBox(height: 24),

                    // Card jam & tombol absen
                    FutureBuilder<AbsenTodayModel?>(
                      future: _absenTodayFuture,
                      builder: (context, absenSnapshot) {
                        if (absenSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        var absenToday = absenSnapshot.data;
                        var isCheckOut = absenToday != null && (absenToday.checkInTime ?? "").isNotEmpty && (absenToday.checkOutTime ?? "").isEmpty;
                        var isDone = absenToday != null && (absenToday.checkInTime ?? "").isNotEmpty && (absenToday.checkOutTime ?? "").isNotEmpty;

                        // Status
                        var statusText = "Belum Absen";
                        var statusBg = const Color(0xFFFFDAD6);
                        var statusFg = const Color(0xFF93000A);
                        var statusDot = const Color(0xFFBA1A1A);
                        var btnText = "CHECK IN";
                        var btnIcon = Icons.login;
                        var btnColors = <Color>[const Color(0xFF003F87), const Color(0xFF0056B3)];

                        if (isCheckOut) {
                          statusText = "Sedang Bekerja";
                          statusBg = Colors.orange.shade100;
                          statusFg = Colors.orange.shade900;
                          statusDot = Colors.orange.shade700;
                          btnText = "CHECK OUT";
                          btnIcon = Icons.logout;
                          btnColors = [Colors.orange.shade700, Colors.orange.shade900];
                        } else if (isDone) {
                          statusText = "Selesai Absen";
                          statusBg = Colors.green.shade100;
                          statusFg = Colors.green.shade900;
                          statusDot = Colors.green.shade700;
                          btnText = "SELESAI";
                          btnIcon = Icons.check_circle;
                          btnColors = [Colors.grey.shade500, Colors.grey.shade600];
                        }

                        return Column(
                          children: [
                            // Card utama
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                children: [
                                  StatusBadge(text: statusText, bgColor: statusBg, textColor: statusFg, dotColor: statusDot),
                                  const SizedBox(height: 24),
                                  Text(
                                    _timeString.isEmpty ? "--:--:--" : _timeString,
                                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF003F87), letterSpacing: -1.5),
                                  ),
                                  const SizedBox(height: 32),
                                  GradientButton(text: btnText, icon: btnIcon, onTap: _navigateToAbsen, colors: btnColors, height: 60),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Color(0xFF727784)),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _isLoadingLocation ? 'Mencari lokasi...' : _currentAddress,
                                          style: const TextStyle(color: Color(0xFF727784), fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Card lokasi + map preview
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0FE),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    child: _currentPosition != null
                                        ? Image.network(
                                            'https://maps.googleapis.com/maps/api/staticmap?center=${_currentPosition!.latitude},${_currentPosition!.longitude}&zoom=15&size=600x200&maptype=roadmap&markers=color:blue%7C${_currentPosition!.latitude},${_currentPosition!.longitude}&key=YOUR_API_KEY',
                                            height: 120, width: double.infinity, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildMapPlaceholder(isDark),
                                          )
                                        : _buildMapPlaceholder(isDark),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: LocationCard(address: _currentAddress, isLoading: _isLoadingLocation, cardColor: Colors.transparent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Statistik kehadiran
                    Text("RINGKASAN KEHADIRAN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: textSecondary)),
                    const SizedBox(height: 16),

                    FutureBuilder<AbsenStatsModel>(
                      future: _absenStatsFuture,
                      builder: (context, statsSnapshot) {
                        if (statsSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (statsSnapshot.hasError) return const Text("Gagal memuat statistik");

                        var stats = statsSnapshot.data!;
                        return Row(
                          children: [
                            StatCard(title: "Hadir", count: stats.totalMasuk.toString(), icon: Icons.check_circle, iconColor: const Color(0xFF003F87), bgColor: const Color(0xFFE8F0FE)),
                            const SizedBox(width: 16),
                            StatCard(title: "Izin", count: stats.totalIzin.toString(), icon: Icons.event_note, iconColor: const Color(0xFF722B00), bgColor: const Color(0xFFFFDBCC)),
                            const SizedBox(width: 16),
                            StatCard(title: "Alpa", count: "0", icon: Icons.cancel, iconColor: const Color(0xFFBA1A1A), bgColor: const Color(0xFFFFDAD6)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Tips
                    const TipsCard(
                      tips: [
                        TipItem(text: "Pastikan GPS aktif sebelum check-in", icon: Icons.gps_fixed),
                        TipItem(text: "Check-in paling lambat pukul 08:00 WIB", icon: Icons.access_time),
                        TipItem(text: "Ajukan izin sebelum hari yang dimaksud", icon: Icons.event_available),
                      ],
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

  // Placeholder map
  Widget _buildMapPlaceholder(bool isDark) {
    return Container(
      height: 120, width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E3A5F), const Color(0xFF0D253F)] : [const Color(0xFFBBD0FF), const Color(0xFFE8F0FE)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
    );
  }
}
