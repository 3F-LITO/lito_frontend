import 'dart:math' show pi;
import 'package:flutter/material.dart';
import '../../../models/sensor_data.dart';
import '../../../utils/pond_health_calculator.dart';

/// Widget Pond Health Score (PHS) — F2.2
///
/// Menampilkan skor kesehatan kolam (0–100) dalam bentuk cincin animasi
/// berwarna berdasarkan kategori:
///   80–100 → Hijau  → "Kolam Sehat"
///   50–79  → Kuning → "Perlu Perhatian"
///   0–49   → Merah  → "Kondisi Kritis"
class PondHealthScore extends StatelessWidget {
  final SensorReading? reading;
  final bool isOffline;

  const PondHealthScore({
    super.key,
    required this.reading,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    if (reading == null) {
      return _PhsRingSkeleton();
    }

    final score = PondHealthCalculator.calculateScore(
      doLevel: reading!.doLevel,
      ph: reading!.ph,
      temperature: reading!.temperature,
      salinity: reading!.salinity,
    );
    final category = PondHealthCalculator.categoryOf(score);

    final (ringColor, label, sublabel) = switch (category) {
      PhsCategory.healthy => (
          const Color(0xFF1D9E75),
          'Kolam Sehat',
          'Semua parameter dalam rentang optimal',
        ),
      PhsCategory.needsAttention => (
          const Color(0xFFEF9F27),
          'Perlu Perhatian',
          'Satu atau lebih parameter mendekati batas',
        ),
      PhsCategory.critical => (
          const Color(0xFFE24B4A),
          'Kondisi Kritis',
          'Parameter kritis — tindakan segera diperlukan',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ringColor.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Cincin animasi ──────────────────────────────────────────────
          _AnimatedRing(score: score, color: ringColor),
          const SizedBox(width: 20),

          // ── Teks kanan ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                if (isOffline) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12, color: Colors.orange.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Berdasarkan data terakhir',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated ring ────────────────────────────────────────────────────────────

class _AnimatedRing extends StatefulWidget {
  final int score;
  final Color color;
  const _AnimatedRing({required this.score, required this.color});

  @override
  State<_AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<_AnimatedRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _prevScore = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _prevScore = widget.score;
  }

  @override
  void didUpdateWidget(_AnimatedRing old) {
    super.didUpdateWidget(old);
    if (widget.score != _prevScore) {
      _anim = Tween<double>(
        begin: _prevScore / 100,
        end: widget.score / 100,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
      _prevScore = widget.score;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: const Size(96, 96),
        painter: _RingPainter(progress: _anim.value, color: widget.color),
        child: SizedBox(
          width: 96,
          height: 96,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.score}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    height: 1,
                  ),
                ),
                Text(
                  'Skor',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0.0–1.0
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - 10) / 2;
    const startAngle = -pi / 2; // mulai dari atas

    // Track (abu-abu)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0,
      2 * pi,
      false,
      Paint()
        ..color = Colors.grey.shade100
        ..strokeWidth = 9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 9
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _PhsRingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 18,
                    width: 120,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 8),
                Container(
                    height: 12,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
