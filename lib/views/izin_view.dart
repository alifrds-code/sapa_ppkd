import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../api/endpoint.dart';
import '../shared_preferences/token_storage.dart';

class IzinView extends StatefulWidget {
  const IzinView({super.key});

  @override
  State<IzinView> createState() => _IzinViewState();
}

class _IzinViewState extends State<IzinView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Untuk Form Ajukan Izin
  final _alasanController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  // Untuk List Izin
  List<Map<String, dynamic>> _izinList = [];
  bool _isLoadingList = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initializeDateFormatting('id_ID', null);
    _fetchIzinList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchIzinList() async {
    setState(() => _isLoadingList = true);
    try {
      final headers = await _getHeaders();

      // Ambil list izin bulan ini
      final now = DateTime.now();
      final start = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month, 1));
      final end = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month + 1, 0));

      final response = await http.get(
        Uri.parse('${Endpoints.izin}?start=$start&end=$end'),
        headers: headers,
      );

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _izinList = List<Map<String, dynamic>>.from(json['data'] ?? []);
        });
      }
    } catch (_) {
      // Silently fail – list tetap kosong
    } finally {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  Future<void> _submitIzin() async {
    if (_selectedDate == null || _alasanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih tanggal dan isi alasan izin!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final headers = await _getHeaders();
      final url = Endpoints.izin;
      final bodyData = {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'alasan_izin': _alasanController.text.trim(),
      };

      debugPrint('[IZIN] POST $url');
      debugPrint('[IZIN] Body: $bodyData');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(bodyData),
      );

      debugPrint('[IZIN] Status: ${response.statusCode}');
      debugPrint('[IZIN] Response: ${response.body}');

      final json = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin berhasil diajukan!'),
            backgroundColor: Colors.green,
          ),
        );
        _alasanController.clear();
        setState(() => _selectedDate = null);
        _fetchIzinList();
        _tabController.animateTo(1); // Pindah ke tab list
      } else {
        final errMsg = json['message']?.toString() ?? 'Gagal mengajukan izin';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${response.statusCode}: $errMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('[IZIN] Exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      if (picked != null && mounted) {
        setState(() => _selectedDate = picked);
      }
    } catch (e) {
      debugPrint('[IZIN] DatePicker error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memilih tanggal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
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
        child: Column(
          children: [
            // ---- HEADER ----
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PENGAJU\nIZIN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_busy,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),

            // ---- TAB BAR ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF003F87),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: Colors.white,
                  unselectedLabelColor: textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Ajukan Izin'),
                    Tab(text: 'Riwayat Izin'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---- TAB CONTENT ----
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // === TAB 1: FORM AJUKAN IZIN ===
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pilih Tanggal
                        Text(
                          'TANGGAL IZIN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedDate != null
                                    ? const Color(0xFF003F87)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF003F87),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate == null
                                      ? 'Pilih Tanggal Izin'
                                      : _formatDate(
                                          _selectedDate!
                                              .toIso8601String()
                                              .split('T')[0],
                                        ),
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? textSecondary
                                        : textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedDate != null)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedDate = null),
                                    child: Icon(
                                      Icons.close,
                                      color: textSecondary,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Alasan Izin
                        Text(
                          'ALASAN IZIN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _alasanController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Tuliskan alasan izin Anda...',
                              hintStyle: TextStyle(color: textSecondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF003F87),
                                  width: 1.5,
                                ),
                              ),
                              fillColor: Colors.transparent,
                              filled: true,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: TextStyle(color: textPrimary),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Tombol Submit
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitIzin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003F87),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : const Text(
                                    'AJUKAN IZIN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // === TAB 2: LIST RIWAYAT IZIN ===
                  _isLoadingList
                      ? const Center(child: CircularProgressIndicator())
                      : _izinList.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _fetchIzinList,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                            children: [
                              SizedBox(
                                height: 300,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.event_available,
                                        size: 64,
                                        color: textSecondary.withOpacity(0.4),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Belum ada pengajuan izin',
                                        style: TextStyle(color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchIzinList,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                            itemCount: _izinList.length,
                            itemBuilder: (ctx, i) {
                              final item = _izinList[i];
                              final status = item['status']?.toString() ?? '';
                              final statusColor = status == 'approved'
                                  ? Colors.green.shade700
                                  : status == 'rejected'
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700;
                              final statusBg = status == 'approved'
                                  ? Colors.green.shade50
                                  : status == 'rejected'
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50;
                              final statusLabel = status == 'approved'
                                  ? 'DISETUJUI'
                                  : status == 'rejected'
                                  ? 'DITOLAK'
                                  : 'MENUNGGU';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatDate(
                                              item['attendance_date']?.toString(),
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item['alasan_izin']?.toString() ?? '-',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
