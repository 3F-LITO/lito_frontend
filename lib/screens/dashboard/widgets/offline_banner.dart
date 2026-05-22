import 'package:flutter/material.dart';

/// Banner offline yang muncul di atas dashboard ketika koneksi tidak tersedia.
/// Menampilkan waktu data cache terakhir jika tersedia.
class OfflineBanner extends StatelessWidget {
  final DateTime? cachedAt;

  const OfflineBanner({super.key, this.cachedAt});

  @override
  Widget build(BuildContext context) {
    final timeStr = cachedAt != null
        ? '${cachedAt!.hour.toString().padLeft(2, '0')}.'
            '${cachedAt!.minute.toString().padLeft(2, '0')} WIB'
        : null;

    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 13, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(
            timeStr != null
                ? 'Mode Offline · Data cache: $timeStr'
                : 'Mode Offline · Data mungkin tidak terkini',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
