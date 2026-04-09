import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../models/absen_history_model.dart';
import '../services/dashboard_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final DashboardService _service = DashboardService();

  late Future<List<AbsenHistoryModel>> _historyFuture;
  DateTime _selectedMonth = DateTime.now();

  // Custom date range filter
  bool _isCustomFilter = false;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) setState(() {});
    });
    _loadHistory();
  }

  void _loadHistory() {
    String start;
    String end;

    if (_isCustomFilter && _customStart != null && _customEnd != null) {
      start = DateFormat('yyyy-MM-dd').format(_customStart!);
      end = DateFormat('yyyy-MM-dd').format(_customEnd!);
    } else {
      start = DateFormat('yyyy-MM-dd')
          .format(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
      end = DateFormat('yyyy-MM-dd')
          .format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));
    }

    setState(() {
      _historyFuture = _service.fetchHistory(startDate: start, endDate: end);
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _isCustomFilter = false;
      _customStart = null;
      _customEnd = null;
    });
    _loadHistory();
  }

  Future<void> _showDateRangeFilter() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _isCustomFilter && _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(
              start: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
              end: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
            ),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF003F87),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _isCustomFilter = true;
        _customStart = picked.start;
        _customEnd = picked.end;
      });
      _loadHistory();
    }
  }

  void _clearCustomFilter() {
    setState(() {
      _isCustomFilter = false;
      _customStart = null;
      _customEnd = null;
    });
    _loadHistory();
  }

  Future<void> _confirmDelete(AbsenHistoryModel item) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Absen?'),
        content: Text(
          'Yakin ingin menghapus data absen tanggal ${_formatDate(item.attendanceDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteAbsen(item.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data absen berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadHistory(); // Refresh list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--:--';
    // raw bisa berupa "HH:mm:ss" atau "HH:mm"
    try {
      final parts = raw.split(':');
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
      return raw;
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'masuk':
        return const Color(0xFF003F87);
      case 'izin':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(String? status) {
    switch (status) {
      case 'masuk':
        return const Color(0xFFE8F0FE);
      case 'izin':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'masuk':
        return 'HADIR';
      case 'izin':
        return 'IZIN';
      default:
        return 'ALPA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF1A1C1E) : const Color(0xFFF9F9F9);
    final cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    final textSecondary =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

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
                    'RIWAYAT\nKEHADIRAN',
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
                      color: const Color(0xFF003F87).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Color(0xFF003F87),
                    ),
                  ),
                ],
              ),
            ),

            // ---- NAVIGASI BULAN + FILTER TANGGAL ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tombol bulan sebelumnya
                        _MonthNavButton(
                          icon: Icons.chevron_left,
                          onTap: () => _changeMonth(-1),
                          isDark: isDark,
                        ),
                        // Label bulan + tombol filter
                        GestureDetector(
                          onTap: _showDateRangeFilter,
                          child: Row(
                            children: [
                              Text(
                                DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.filter_list, size: 18, color: const Color(0xFF003F87)),
                            ],
                          ),
                        ),
                        // Tombol bulan berikutnya
                        _MonthNavButton(
                          icon: Icons.chevron_right,
                          onTap: _selectedMonth.month == DateTime.now().month &&
                                  _selectedMonth.year == DateTime.now().year
                              ? null
                              : () => _changeMonth(1),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  // Tampilkan info filter kustom jika aktif
                  if (_isCustomFilter)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003F87).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, size: 16, color: Color(0xFF003F87)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${DateFormat('dd MMM yyyy', 'id_ID').format(_customStart!)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_customEnd!)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF003F87)),
                              ),
                            ),
                            GestureDetector(
                              onTap: _clearCustomFilter,
                              child: const Icon(Icons.close, size: 18, color: Color(0xFF003F87)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---- LIST RIWAYAT ----
            Expanded(
              child: FutureBuilder<List<AbsenHistoryModel>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade400, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat riwayat',
                              style: TextStyle(color: textSecondary),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadHistory,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 64, color: textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada data absensi\ndi bulan ini',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadHistory(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final bool isComplete = (item.checkOutTime ?? '').isNotEmpty;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _showDetailSheet(item, isDark, cardColor, textPrimary, textSecondary),
                            child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row atas: tanggal + badge status + tombol hapus
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusBg(item.status),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                        child: Text(
                                          _statusLabel(item.status),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                            color: _statusColor(item.status),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Tombol Hapus
                                      GestureDetector(
                                        onTap: () => _confirmDelete(item),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red.shade600,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Tanggal
                                  Text(
                                    _formatDate(item.attendanceDate),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Row jam masuk & pulang
                                  Row(
                                    children: [
                                      _TimeBox(
                                        label: 'MASUK',
                                        time: _formatTime(item.checkInTime),
                                        icon: Icons.login,
                                        color: const Color(0xFF003F87),
                                        bgColor: const Color(0xFFE8F0FE),
                                        isDark: isDark,
                                      ),
                                      const SizedBox(width: 12),
                                      _TimeBox(
                                        label: 'PULANG',
                                        time: _formatTime(item.checkOutTime),
                                        icon: Icons.logout,
                                        color: isComplete
                                            ? Colors.green.shade700
                                            : Colors.grey,
                                        bgColor: isComplete
                                            ? Colors.green.shade50
                                            : Colors.grey.shade100,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),

                                  // Lokasi check-in (jika ada)
                                  if ((item.checkInAddress ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item.checkInAddress!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Hint tap
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.touch_app, size: 12, color: textSecondary.withOpacity(0.5)),
                                        const SizedBox(width: 4),
                                        Text("Ketuk untuk detail", style: TextStyle(fontSize: 10, color: textSecondary.withOpacity(0.5))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(AbsenHistoryModel item, bool isDark, Color cardColor, Color textPrimary, Color textSecondary) {
    final bgSheet = isDark ? const Color(0xFF232527) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgSheet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusBg(item.status),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _statusLabel(item.status),
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            letterSpacing: 1.0, color: _statusColor(item.status),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today, size: 16, color: textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(item.attendanceDate),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Detail rows
                  _detailRow("JAM MASUK", item.checkInTime ?? '-', Icons.login, const Color(0xFF003F87), textPrimary, textSecondary),
                  const SizedBox(height: 16),
                  _detailRow("JAM PULANG", item.checkOutTime ?? '-', Icons.logout, Colors.green.shade700, textPrimary, textSecondary),
                  const SizedBox(height: 16),
                  _detailRow("LOKASI MASUK", item.checkInAddress ?? '-', Icons.location_on, Colors.orange.shade700, textPrimary, textSecondary),
                  const SizedBox(height: 16),
                  _detailRow("LOKASI PULANG", item.checkOutAddress ?? '-', Icons.location_on_outlined, Colors.teal, textPrimary, textSecondary),

                  if (item.checkInLat != null && item.checkInLng != null) ...[
                    const SizedBox(height: 16),
                    _detailRow("KOORDINAT MASUK", "${item.checkInLat}, ${item.checkInLng}", Icons.my_location, Colors.blue, textPrimary, textSecondary),
                  ],
                  if (item.checkOutLat != null && item.checkOutLng != null) ...[
                    const SizedBox(height: 16),
                    _detailRow("KOORDINAT PULANG", "${item.checkOutLat}, ${item.checkOutLng}", Icons.my_location, Colors.purple, textPrimary, textSecondary),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value, IconData icon, Color iconColor, Color textPrimary, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- WIDGET HELPER ----

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _MonthNavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.transparent
              : const Color(0xFF003F87).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDisabled
              ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
              : const Color(0xFF003F87),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isDark;

  const _TimeBox({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration:
                  BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: color,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1C1C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
