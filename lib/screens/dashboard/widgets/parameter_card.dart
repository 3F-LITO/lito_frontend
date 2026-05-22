import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/sensor_data.dart';
import '../../../utils/trend_calculator.dart';

// ─── Threshold constants (§3.2) ──────────────────────────────────────────────

enum ParamStatus { normal, warning, danger }

class _Threshold {
  final double dangerLow;
  final double warnLow;
  final double warnHigh;
  final double dangerHigh;
  const _Threshold({
    required this.dangerLow,
    required this.warnLow,
    required this.warnHigh,
    required this.dangerHigh,
  });
}

const _thresholds = {
  'do': _Threshold(dangerLow: 0, warnLow: 4.0, warnHigh: 8.0, dangerHigh: 12),
  'temp': _Threshold(dangerLow: 15, warnLow: 26, warnHigh: 32, dangerHigh: 38),
  'sal': _Threshold(dangerLow: 0, warnLow: 15, warnHigh: 25, dangerHigh: 40),
  'ph': _Threshold(dangerLow: 6, warnLow: 7.5, warnHigh: 8.5, dangerHigh: 10),
};

ParamStatus _getStatus(String key, double value) {
  final t = _thresholds[key];
  if (t == null) return ParamStatus.normal;
  if (value < t.warnLow || value > t.warnHigh) {
    if (value < t.dangerLow + (t.warnLow - t.dangerLow) / 2 ||
        value > t.warnHigh + (t.dangerHigh - t.warnHigh) / 2) {
      return ParamStatus.danger;
    }
    // For DO and pH: anything outside normal is danger per spec
    if (key == 'do' && value < 4.0) return ParamStatus.danger;
    if (key == 'ph' && (value < 7.5 || value > 8.5)) return ParamStatus.danger;
    return ParamStatus.warning;
  }
  return ParamStatus.normal;
}

Color _statusColor(ParamStatus s) {
  switch (s) {
    case ParamStatus.normal:
      return const Color(0xFF1D9E75);
    case ParamStatus.warning:
      return const Color(0xFFEF9F27);
    case ParamStatus.danger:
      return const Color(0xFFE24B4A);
  }
}

String _statusLabel(ParamStatus s) {
  switch (s) {
    case ParamStatus.normal:
      return 'Normal';
    case ParamStatus.warning:
      return 'Waspada';
    case ParamStatus.danger:
      return 'Bahaya';
  }
}

// ─── Trend helpers (F2.3) ────────────────────────────────────────────────────
// Delegasi ke TrendCalculator — threshold dari spec: do=0.3, temp=0.5, sal=0.5, ph=0.1

typedef Trend = SensorTrend;

// ─── Parameter definitions ────────────────────────────────────────────────────

class _ParamDef {
  final String key;
  final String label;
  final String unit;
  final IconData icon;
  const _ParamDef(this.key, this.label, this.unit, this.icon);
}

const _params = [
  _ParamDef('do', 'Oksigen (DO)', 'mg/L', Icons.waves),
  _ParamDef('temp', 'Suhu', '°C', Icons.thermostat),
  _ParamDef('sal', 'Salinitas', 'ppt', Icons.water_drop),
  _ParamDef('ph', 'pH', '', Icons.science),
];

double _paramValue(String key, SensorReading r) {
  switch (key) {
    case 'do':
      return r.doLevel;
    case 'temp':
      return r.temperature;
    case 'sal':
      return r.salinity;
    case 'ph':
      return r.ph;
    default:
      return 0;
  }
}

// ─── Public widget ────────────────────────────────────────────────────────────

/// Kartu parameter sensor real-time (F2.1 + F2.3).
///
/// Menerima [latest] (bacaan terkini), [baseline] (bacaan ~30 menit lalu
/// untuk tren F2.3), dan [history] untuk sparkline mini 1 jam.
class ParameterCardsGrid extends StatefulWidget {
  final SensorReading? latest;
  final SensorReading? baseline; // ~30 menit lalu (F2.3)
  final List<SensorReading> history;
  final bool isOffline;

  const ParameterCardsGrid({
    super.key,
    required this.latest,
    required this.baseline,
    required this.history,
    required this.isOffline,
  });

  @override
  State<ParameterCardsGrid> createState() => _ParameterCardsGridState();
}

class _ParameterCardsGridState extends State<ParameterCardsGrid> {
  String? _expandedKey;

  @override
  Widget build(BuildContext context) {
    if (widget.latest == null) {
      return _buildSkeleton();
    }

    return Column(
      children: _params.map((def) {
        final current = _paramValue(def.key, widget.latest!);
        final trend =
            TrendCalculator.trendFor(def.key, current, widget.baseline);
        final pStatus = _getStatus(def.key, current);
        final isExpanded = _expandedKey == def.key;

        // Extract sparkline points for this parameter
        final sparkPoints = widget.history.reversed
            .toList()
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), _paramValue(def.key, e.value)))
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SingleParamCard(
            def: def,
            value: current,
            status: pStatus,
            trend: trend,
            isSimulated: widget.latest!.isSimulated,
            isOffline: widget.isOffline,
            cachedAt: widget.isOffline ? widget.latest!.timestamp : null,
            isExpanded: isExpanded,
            sparkPoints: sparkPoints,
            onTap: () => setState(() {
              _expandedKey = isExpanded ? null : def.key;
            }),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
          4,
          (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )),
    );
  }
}

// ─── Single card ──────────────────────────────────────────────────────────────

class _SingleParamCard extends StatelessWidget {
  final _ParamDef def;
  final double value;
  final ParamStatus status;
  final Trend trend;
  final bool isSimulated;
  final bool isOffline;
  final DateTime? cachedAt;
  final bool isExpanded;
  final List<FlSpot> sparkPoints;
  final VoidCallback onTap;

  const _SingleParamCard({
    required this.def,
    required this.value,
    required this.status,
    required this.trend,
    required this.isSimulated,
    required this.isOffline,
    required this.cachedAt,
    required this.isExpanded,
    required this.sparkPoints,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);
    final label = _statusLabel(status);
    final valueStr =
        value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: statusColor.withAlpha(isExpanded ? 30 : 20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
                isExpanded ? statusColor.withAlpha(80) : Colors.grey.shade100,
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: icon+label / badges ─────────────────────────────
              Row(
                children: [
                  Icon(def.icon, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    def.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  // SIMULASI badge
                  if (isSimulated)
                    _Badge(
                      label: isOffline ? 'SIMULASI · Offline' : 'SIMULASI',
                      color: Colors.grey.shade400,
                      icon: isOffline ? Icons.wifi_off : null,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Value + unit ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valueStr,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      height: 1,
                    ),
                  ),
                  if (def.unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        def.unit,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // ── Status dot + trend ────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _TrendChip(trend: trend),
                ],
              ),

              // ── Offline cache note ────────────────────────────────────────
              if (isOffline && cachedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12, color: Colors.orange.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Data cache terakhir · ${_formatTime(cachedAt!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Sparkline (expanded) ──────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade100, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tren 1 Jam Terakhir',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Live',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 64,
                            child: sparkPoints.length < 2
                                ? Center(
                                    child: Text(
                                      'Belum cukup data',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  )
                                : _SparklineChart(
                                    spots: sparkPoints,
                                    color: statusColor,
                                  ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m WIB';
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trend chip ───────────────────────────────────────────────────────────────

class _TrendChip extends StatelessWidget {
  final Trend trend;
  const _TrendChip({required this.trend});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (trend) {
      Trend.up => (
          Icons.arrow_upward_rounded,
          '↑ Naik',
          const Color(0xFF1D9E75)
        ),
      Trend.down => (
          Icons.arrow_downward_rounded,
          '↓ Turun',
          const Color(0xFFE24B4A)
        ),
      Trend.stable => (Icons.arrow_forward_rounded, '→ Stabil', Colors.grey),
    };

    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Sparkline chart ──────────────────────────────────────────────────────────

class _SparklineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  const _SparklineChart({required this.spots, required this.color});

  @override
  Widget build(BuildContext context) {
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 0.5;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 0.5;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }
}
