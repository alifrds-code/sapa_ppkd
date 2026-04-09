import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../api/endpoint.dart';
import '../models/absen_today_model.dart';
import '../services/dashboard_service.dart';
import '../shared_preferences/token_storage.dart';

class AbsenView extends StatefulWidget {
  const AbsenView({super.key});

  @override
  State<AbsenView> createState() => _AbsenViewState();
}

class _AbsenViewState extends State<AbsenView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DashboardService _dashboardService = DashboardService();

  // Lokasi
  bool _isLoadingLocation = true;
  Position? _currentPosition;
  String _currentAddress = "Mencari lokasi...";
  GoogleMapController? _mapController;

  // Absen status
  AbsenTodayModel? _absenToday;
  bool _isLoadingAbsen = true;
  bool _isSubmittingAbsen = false;

  // Izin form
  final _alasanController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSubmittingIzin = false;

  // Izin list
  List<Map<String, dynamic>> _izinList = [];
  bool _isLoadingIzinList = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initializeDateFormatting('id_ID', null);
    _getCurrentLocation();
    _loadAbsenToday();
    _fetchIzinList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alasanController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIKA LOKASI
  // ============================================================
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("GPS tidak aktif. Nyalakan GPS.");

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

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
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

  // ============================================================
  // LOGIKA ABSEN
  // ============================================================
  Future<void> _loadAbsenToday() async {
    setState(() => _isLoadingAbsen = true);
    try {
      final result = await _dashboardService.fetchAbsenToday();
      if (mounted) setState(() { _absenToday = result; _isLoadingAbsen = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingAbsen = false);
    }
  }

  Future<void> _handleAbsen() async {
    if (_currentPosition == null) {
      _showSnackBar("Tunggu lokasi ditemukan!", Colors.orange);
      return;
    }

    bool isCheckIn = _absenToday == null || (_absenToday!.checkInTime ?? "").isEmpty;

    setState(() => _isSubmittingAbsen = true);
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
      _showSnackBar(
        isCheckIn ? "Berhasil Check In! ✅" : "Berhasil Check Out! ✅",
        Colors.green,
      );
      _loadAbsenToday();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll("Exception: ", ""), Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmittingAbsen = false);
    }
  }

  // ============================================================
  // LOGIKA IZIN
  // ============================================================
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchIzinList() async {
    setState(() => _isLoadingIzinList = true);
    try {
      final headers = await _getHeaders();
      final now = DateTime.now();
      final start = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
      final end = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));

      final response = await http.get(
        Uri.parse('${Endpoints.izin}?start=$start&end=$end'),
        headers: headers,
      );

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _izinList = List<Map<String, dynamic>>.from(json['data'] ?? []);
          });
        }
      }
    } catch (_) {
      // Silently fail
    } finally {
      if (mounted) setState(() => _isLoadingIzinList = false);
    }
  }

  Future<void> _submitIzin() async {
    if (_selectedDate == null || _alasanController.text.trim().isEmpty) {
      _showSnackBar('Harap pilih tanggal dan isi alasan izin!', Colors.red);
      return;
    }

    setState(() => _isSubmittingIzin = true);
    try {
      final headers = await _getHeaders();
      final bodyData = {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'alasan_izin': _alasanController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(Endpoints.izin),
        headers: headers,
        body: jsonEncode(bodyData),
      );

      debugPrint('[IZIN] Status: ${response.statusCode}');
      debugPrint('[IZIN] Response: ${response.body}');

      final json = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Izin berhasil diajukan! ✅', Colors.green);
        _alasanController.clear();
        setState(() => _selectedDate = null);
        _fetchIzinList();
      } else {
        final errMsg = json['message']?.toString() ?? 'Gagal mengajukan izin';
        _showSnackBar('Error ${response.statusCode}: $errMsg', Colors.red);
      }
    } catch (e) {
      debugPrint('[IZIN] Exception: $e');
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmittingIzin = false);
    }
  }

  Future<void> _pickDate() async {
    try {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? now,
        firstDate: now,
        lastDate: DateTime(now.year, now.month + 3, 0),
        locale: const Locale('id', 'ID'),
      );
      if (picked != null && mounted) setState(() => _selectedDate = picked);
    } catch (e) {
      debugPrint('[IZIN] DatePicker error: $e');
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF9F9F9);
    final cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          "Absensi",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF003F87),
          indicatorWeight: 3,
          labelColor: const Color(0xFF003F87),
          unselectedLabelColor: textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "Check In / Out"),
            Tab(text: "Ajukan Izin"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCheckInOutTab(isDark, cardColor, textPrimary, textSecondary),
          _buildIzinTab(isDark, cardColor, textPrimary, textSecondary),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1: CHECK IN / CHECK OUT
  // ============================================================
  Widget _buildCheckInOutTab(bool isDark, Color cardColor, Color textPrimary, Color textSecondary) {
    bool isCheckIn = _absenToday == null || (_absenToday?.checkInTime ?? "").isEmpty;
    bool isCheckOut = _absenToday != null && (_absenToday!.checkInTime ?? "").isNotEmpty && (_absenToday!.checkOutTime ?? "").isEmpty;
    bool isDone = _absenToday != null && (_absenToday!.checkInTime ?? "").isNotEmpty && (_absenToday!.checkOutTime ?? "").isNotEmpty;

    String statusText = "Belum Absen";
    Color statusBg = const Color(0xFFFFDAD6);
    Color statusFg = const Color(0xFF93000A);
    String buttonText = "CHECK IN";
    IconData buttonIcon = Icons.login;
    List<Color> gradient = [const Color(0xFF003F87), const Color(0xFF0056B3)];

    if (isCheckOut) {
      statusText = "Sedang Bekerja";
      statusBg = Colors.orange.shade100;
      statusFg = Colors.orange.shade900;
      buttonText = "CHECK OUT";
      buttonIcon = Icons.logout;
      gradient = [Colors.orange.shade700, Colors.orange.shade900];
    } else if (isDone) {
      statusText = "Selesai Absen ✅";
      statusBg = Colors.green.shade100;
      statusFg = Colors.green.shade900;
      buttonText = "SELESAI";
      buttonIcon = Icons.check_circle;
      gradient = [Colors.grey.shade500, Colors.grey.shade600];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        children: [
          // --- Google Maps ---
          Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _currentPosition != null
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        zoom: 16,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) => _mapController = controller,
                      markers: {
                        Marker(
                          markerId: const MarkerId('myLocation'),
                          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          infoWindow: InfoWindow(title: 'Lokasi Saya', snippet: _currentAddress),
                        ),
                      },
                    )
                  : Container(
                      color: isDark ? const Color(0xFF2C2E30) : const Color(0xFFE8F0FE),
                      child: Center(
                        child: _isLoadingLocation
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_off, size: 48, color: textSecondary),
                                  const SizedBox(height: 8),
                                  Text(_currentAddress, style: TextStyle(color: textSecondary)),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _getCurrentLocation,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text("Coba Lagi"),
                                  ),
                                ],
                              ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Lokasi Info ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003F87).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: Color(0xFF003F87), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("LOKASI SAYA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        _isLoadingLocation ? "Mencari lokasi..." : _currentAddress,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Status Badge ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(100)),
            child: Text(
              statusText.toUpperCase(),
              style: TextStyle(color: statusFg, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 20),

          // --- Tombol Absen ---
          InkWell(
            onTap: isDone || _isSubmittingAbsen ? null : _handleAbsen,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient, begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: _isSubmittingAbsen
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(buttonIcon, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ],
                    ),
            ),
          ),

          // --- Info Absen Hari Ini ---
          if (_absenToday != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ABSEN HARI INI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _buildInfoRow("Check In", _absenToday!.checkInTime ?? "-", textPrimary, textSecondary),
                  const SizedBox(height: 8),
                  _buildInfoRow("Check Out", _absenToday!.checkOutTime ?? "-", textPrimary, textSecondary),
                  if (_absenToday!.checkInAddress != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow("Lokasi In", _absenToday!.checkInAddress!, textPrimary, textSecondary),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ============================================================
  // TAB 2: AJUKAN IZIN
  // ============================================================
  Widget _buildIzinTab(bool isDark, Color cardColor, Color textPrimary, Color textSecondary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Form Izin ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("AJUKAN IZIN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1.5)),
                const SizedBox(height: 20),

                // Pilih Tanggal
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F6FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFDDE3EC)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: const Color(0xFF003F87)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate!)
                                : "Pilih Tanggal Izin",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedDate != null ? textPrimary : textSecondary,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alasan
                TextField(
                  controller: _alasanController,
                  maxLines: 4,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Tulis alasan izin...",
                    hintStyle: TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFDDE3EC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFDDE3EC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF003F87), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Submit
                InkWell(
                  onTap: _isSubmittingIzin ? null : _submitIzin,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003F87), Color(0xFF0056B3)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _isSubmittingIzin
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("AJUKAN IZIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Riwayat Izin ---
          Text("RIWAYAT IZIN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 12),

          if (_isLoadingIzinList)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_izinList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text('Belum ada pengajuan izin', style: TextStyle(color: textSecondary, fontSize: 14)),
                ],
              ),
            )
          else
            ...List.generate(_izinList.length, (i) {
              final item = _izinList[i];
              final status = item['status']?.toString() ?? '';
              Color statusColor = Colors.orange;
              String statusLabel = 'MENUNGGU';
              if (status == 'approved') { statusColor = Colors.green; statusLabel = 'DISETUJUI'; }
              else if (status == 'rejected') { statusColor = Colors.red; statusLabel = 'DITOLAK'; }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                        ),
                        const Spacer(),
                        Text(_formatDate(item['attendance_date']?.toString()), style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(item['alasan_izin']?.toString() ?? '-', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
