import 'package:flutter/material.dart';

enum TrendDirection { up, down, stable }

/// Indikator tren dengan ikon dan warna sesuai arah perubahan.
class TrendIndicator extends StatelessWidget {
  final TrendDirection direction;
  final double size;

  const TrendIndicator({
    super.key,
    required this.direction,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (direction) {
      TrendDirection.up => (Icons.trending_up, const Color(0xFF1D9E75)),
      TrendDirection.down => (Icons.trending_down, const Color(0xFFE24B4A)),
      TrendDirection.stable => (Icons.trending_flat, const Color(0xFF9CA3AF)),
    };
    return Icon(icon, size: size, color: color);
  }
}
