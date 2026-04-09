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
import '../widgets/common/gradient_button.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/location_card.dart';
import '../widgets/cards/izin_card.dart';

class AbsenView extends StatefulWidget {
  const AbsenView({super.key});

  @override
  State<AbsenView> createState() => _AbsenViewState();
}

class _AbsenViewState extends State<AbsenView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DashboardService _dashboardService = DashboardService();

  // Lokasi
  bool _isLoadingLocation = true;
  Position? _currentPosition;
  String _currentAddress = "Mencari lokasi...";
  GoogleMapController? _mapController;

  // Status absen hari ini
  AbsenTodayModel? _absenToday;
  bool _isSubmittingAbsen = false;

  // Form izin
  final _alasanController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSubmittingIzin = false;

  // List izin
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
        _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
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

  Future<void> _loadAbsenToday() async {
    // loading state handled by setState
    try {
      var result = await _dashboardService.fetchAbsenToday();
      if (mounted) setState(() { _absenToday = result; });
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleAbsen() async {
    if (_currentPosition == null) { _showSnackBar("Tunggu lokasi ditemukan!", Colors.orange); return; }

    var isCheckIn = _absenToday == null || (_absenToday!.checkInTime ?? "").isEmpty;
    setState(() => _isSubmittingAbsen = true);
    try {
      if (isCheckIn) {
        await _dashboardService.checkIn(lat: _currentPosition!.latitude, lng: _currentPosition!.longitude, address: _currentAddress);
      } else {
        await _dashboardService.checkOut(lat: _currentPosition!.latitude, lng: _currentPosition!.longitude, address: _currentAddress);
      }
      if (!mounted) return;
      _showSnackBar(isCheckIn ? "Berhasil Check In! ✅" : "Berhasil Check Out! ✅", Colors.green);
      _loadAbsenToday();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll("Exception: ", ""), Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmittingAbsen = false);
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    var token = await TokenStorage.getToken();
    return { 'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token' };
  }

  Future<void> _fetchIzinList() async {
    setState(() => _isLoadingIzinList = true);
    try {
      var headers = await _getHeaders();
      var now = DateTime.now();
      var start = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
      var end = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));
      var response = await http.get(Uri.parse('${Endpoints.izin}?start=$start&end=$end'), headers: headers);
      var json = jsonDecode(response.body);
      if (response.statusCode == 200 && mounted) {
        setState(() { _izinList = List<Map<String, dynamic>>.from(json['data'] ?? []); });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingIzinList = false);
    }
  }

  Future<void> _submitIzin() async {
    if (_selectedDate == null || _alasanController.text.trim().isEmpty) {
      _showSnackBar('Harap pilih tanggal dan isi alasan izin!', Colors.red); return;
    }
    setState(() => _isSubmittingIzin = true);
    try {
      var headers = await _getHeaders();
      var response = await http.post(Uri.parse(Endpoints.izin), headers: headers, body: jsonEncode({
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'alasan_izin': _alasanController.text.trim(),
      }));
      print('[IZIN] Status: ${response.statusCode}');
      var json = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Izin berhasil diajukan! ✅', Colors.green);
        _alasanController.clear();
        setState(() => _selectedDate = null);
        _fetchIzinList();
      } else {
        _showSnackBar('Error ${response.statusCode}: ${json['message'] ?? 'Gagal'}', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan: ${e.toString().replaceAll("Exception: ", "")}', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmittingIzin = false);
    }
  }

  Future<void> _pickDate() async {
    try {
      var now = DateTime.now();
      var picked = await showDatePicker(
        context: context, initialDate: _selectedDate ?? now,
        firstDate: now, lastDate: DateTime(now.year, now.month + 3, 0),
        locale: const Locale('id', 'ID'),
      );
      if (picked != null && mounted) setState(() => _selectedDate = picked);
    } catch (e) { print('[IZIN] DatePicker error: $e'); }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try { return DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(raw)); } catch (_) { return raw; }
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
      appBar: AppBar(
        backgroundColor: bgColor.withOpacity(0.9), elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20), onPressed: () => Navigator.pop(context, true)),
        title: Text("Absensi", style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController, indicatorColor: const Color(0xFF003F87), indicatorWeight: 3,
          labelColor: const Color(0xFF003F87), unselectedLabelColor: textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [Tab(text: "Check In / Out"), Tab(text: "Ajukan Izin")],
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

  // Tab 1: Check In / Check Out
  Widget _buildCheckInOutTab(bool isDark, Color cardColor, Color textPrimary, Color textSecondary) {

    var isCheckOut = _absenToday != null && (_absenToday!.checkInTime ?? "").isNotEmpty && (_absenToday!.checkOutTime ?? "").isEmpty;
    var isDone = _absenToday != null && (_absenToday!.checkInTime ?? "").isNotEmpty && (_absenToday!.checkOutTime ?? "").isNotEmpty;

    var statusText = "Belum Absen";
    var statusBg = const Color(0xFFFFDAD6);
    var statusFg = const Color(0xFF93000A);
    var btnText = "CHECK IN";
    var btnIcon = Icons.login;
    var btnColors = <Color>[const Color(0xFF003F87), const Color(0xFF0056B3)];

    if (isCheckOut) {
      statusText = "Sedang Bekerja"; statusBg = Colors.orange.shade100; statusFg = Colors.orange.shade900;
      btnText = "CHECK OUT"; btnIcon = Icons.logout; btnColors = [Colors.orange.shade700, Colors.orange.shade900];
    } else if (isDone) {
      statusText = "Selesai Absen ✅"; statusBg = Colors.green.shade100; statusFg = Colors.green.shade900;
      btnText = "SELESAI"; btnIcon = Icons.check_circle; btnColors = [Colors.grey.shade500, Colors.grey.shade600];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        children: [
          // Google Maps
          Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _currentPosition != null
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), zoom: 16),
                      myLocationEnabled: true, myLocationButtonEnabled: false, zoomControlsEnabled: false, mapToolbarEnabled: false,
                      onMapCreated: (controller) => _mapController = controller,
                      markers: { Marker(markerId: const MarkerId('myLocation'), position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), infoWindow: InfoWindow(title: 'Lokasi Saya', snippet: _currentAddress)) },
                    )
                  : Container(
                      color: isDark ? const Color(0xFF2C2E30) : const Color(0xFFE8F0FE),
                      child: Center(
                        child: _isLoadingLocation
                            ? const CircularProgressIndicator()
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.location_off, size: 48, color: textSecondary),
                                const SizedBox(height: 8),
                                Text(_currentAddress, style: TextStyle(color: textSecondary)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(onPressed: _getCurrentLocation, icon: const Icon(Icons.refresh, size: 18), label: const Text("Coba Lagi")),
                              ]),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          LocationCard(address: _currentAddress, isLoading: _isLoadingLocation),
          const SizedBox(height: 20),

          StatusBadge(text: statusText, bgColor: statusBg, textColor: statusFg),
          const SizedBox(height: 20),

          GradientButton(text: btnText, icon: btnIcon, onTap: isDone ? null : _handleAbsen, isLoading: _isSubmittingAbsen, colors: btnColors, height: 60),

          // Info absen hari ini
          if (_absenToday != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("ABSEN HARI INI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1)),
                const SizedBox(height: 12),
                _infoRow("Check In", _absenToday!.checkInTime ?? "-", textPrimary, textSecondary),
                const SizedBox(height: 8),
                _infoRow("Check Out", _absenToday!.checkOutTime ?? "-", textPrimary, textSecondary),
                if (_absenToday!.checkInAddress != null) ...[const SizedBox(height: 8), _infoRow("Lokasi In", _absenToday!.checkInAddress!, textPrimary, textSecondary)],
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color tp, Color ts) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: ts, fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(fontSize: 13, color: tp, fontWeight: FontWeight.w700)),
    ]);
  }

  // Tab 2: Ajukan Izin
  Widget _buildIzinTab(bool isDark, Color cardColor, Color textPrimary, Color textSecondary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Form izin
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text("AJUKAN IZIN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 20),

              // Pilih tanggal
              InkWell(
                onTap: _pickDate, borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F6FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFDDE3EC)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, size: 20, color: Color(0xFF003F87)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                      _selectedDate != null ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate!) : "Pilih Tanggal Izin",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _selectedDate != null ? textPrimary : textSecondary),
                    )),
                    Icon(Icons.arrow_drop_down, color: textSecondary),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Input alasan
              TextField(
                controller: _alasanController, maxLines: 4,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Tulis alasan izin...", hintStyle: TextStyle(color: textSecondary),
                  filled: true, fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F6FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFDDE3EC))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFDDE3EC))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF003F87), width: 2)),
                ),
              ),
              const SizedBox(height: 20),

              GradientButton(text: "AJUKAN IZIN", onTap: _submitIzin, isLoading: _isSubmittingIzin),
            ]),
          ),
          const SizedBox(height: 24),

          // Riwayat izin
          Text("RIWAYAT IZIN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1.5)),
          const SizedBox(height: 12),

          if (_isLoadingIzinList)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_izinList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Icon(Icons.event_available, size: 48, color: textSecondary.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text('Belum ada pengajuan izin', style: TextStyle(color: textSecondary, fontSize: 14)),
              ]),
            )
          else
            ...List.generate(_izinList.length, (i) {
              var item = _izinList[i];
              return IzinCard(
                status: item['status']?.toString() ?? '',
                date: _formatDate(item['attendance_date']?.toString()),
                alasan: item['alasan_izin']?.toString() ?? '-',
              );
            }),
        ],
      ),
    );
  }
}
