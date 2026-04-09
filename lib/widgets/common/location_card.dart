import 'package:flutter/material.dart';

// Card info lokasi dengan icon + alamat
// Dipake di Dashboard dan Absen
class LocationCard extends StatelessWidget {
  final String address;
  final bool isLoading;
  final Color? cardColor; // null = pakai default dari tema

  const LocationCard({
    super.key,
    required this.address,
    this.isLoading = false,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;
    var bgColor = cardColor ?? (isDark ? const Color(0xFF2C2E30) : Colors.white);
    var textPrimary = isDark ? Colors.white : const Color(0xFF1A1C1C);
    var textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
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
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF003F87),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
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
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? "Mencari lokasi..." : address,
                  style: TextStyle(
                    fontSize: 14,
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
    );
  }
}
