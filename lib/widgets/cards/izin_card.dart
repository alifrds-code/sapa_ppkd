import 'package:flutter/material.dart';

// Card riwayat izin di halaman Absen (Tab 2)
class IzinCard extends StatelessWidget {
  final String status;
  final String date;
  final String alasan;

  const IzinCard({
    super.key,
    required this.status,
    required this.date,
    required this.alasan,
  });

  // Tentukan warna dan label sesuai status
  Color get _statusColor {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange; // pending/menunggu
  }

  String get _statusLabel {
    if (status == 'approved') return 'DISETUJUI';
    if (status == 'rejected') return 'DITOLAK';
    return 'MENUNGGU';
  }

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;
    var cardColor = isDark ? const Color(0xFF2C2E30) : Colors.white;
    var textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    var textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge status + tanggal
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Alasan izin
          Text(
            alasan,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
