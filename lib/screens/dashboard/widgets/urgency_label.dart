import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/sensor_data.dart';
import '../../../providers/sensor_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../utils/urgency_calculator.dart';

/// Badge label status tambak — AMAN / WASPADA / BAHAYA.
/// Ditampilkan di bawah PondHealthScore di DashboardScreen.
/// BAHAYA: latar merah + animasi pulse. Offline: catatan cache.
class UrgencyLabel extends StatefulWidget {
  const UrgencyLabel({super.key});

  @override
  State<UrgencyLabel> createState() => _UrgencyLabelState();
}

class _UrgencyLabelState extends State<UrgencyLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SensorProvider, ConnectivityProvider>(
      builder: (_, sensor, conn, __) {
        final SensorReading? latest = sensor.latest;
        final UrgencyLevel level = getUrgency(latest);
        final bool isOffline = conn.isOffline || sensor.isOffline;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LevelBadge(level: level, pulse: _scale),
            if (isOffline) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 12, color: Color(0xFFD97706)),
                  SizedBox(width: 4),
                  Text(
                    'Dari data cache terakhir',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFD97706),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Badge chip ─────────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final UrgencyLevel level;
  final Animation<double> pulse;

  const _LevelBadge({required this.level, required this.pulse});

  Color get _bg {
    switch (level) {
      case UrgencyLevel.bahaya:
        return const Color(0xFFE24B4A);
      case UrgencyLevel.waspada:
        return const Color(0xFFEF9F27);
      case UrgencyLevel.aman:
        return const Color(0xFF1D9E75);
    }
  }

  IconData get _icon {
    switch (level) {
      case UrgencyLevel.bahaya:
        return Icons.warning_rounded;
      case UrgencyLevel.waspada:
        return Icons.info_rounded;
      case UrgencyLevel.aman:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: level == UrgencyLevel.bahaya
            ? [
                BoxShadow(
                  color: _bg.withAlpha(100),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Status: ${level.label}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    if (level == UrgencyLevel.bahaya) {
      return ScaleTransition(scale: pulse, child: chip);
    }
    return chip;
  }
}
