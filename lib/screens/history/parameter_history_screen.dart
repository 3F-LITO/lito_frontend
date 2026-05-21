import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/sensor_data.dart';
import '../../providers/sensor_provider.dart';

// ─── Threshold constants (§3.2) — sama persis dengan parameter_card.dart ──────

class _Thr {
  final double warnLow;
  final double warnHigh;
  const _Thr(this.warnLow, this.warnHigh);
}

const _thresholds = {
  'do': _Thr(4.0, 8.0),
  'temp': _Thr(26.0, 32.0),
  'sal': _Thr(15.0, 25.0),
  'ph': _Thr(7.5, 8.5),
};

bool _isDanger(SensorReading r) {
  bool bad(String key, double val) {
    final t = _thresholds[key]!;
    return val < t.warnLow || val > t.warnHigh;
  }

  return bad('do', r.doLevel) ||
      bad('temp', r.temperature) ||
      bad('sal', r.salinity) ||
      bad('ph', r.ph);
}

bool _isBadVal(String key, double val) {
  final t = _thresholds[key];
  if (t == null) return false;
  return val < t.warnLow || val > t.warnHigh;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ParameterHistoryScreen extends StatefulWidget {
  const ParameterHistoryScreen({super.key});

  @override
  State<ParameterHistoryScreen> createState() => _ParameterHistoryScreenState();
}

class _ParameterHistoryScreenState extends State<ParameterHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SensorProvider>().loadHistory24h();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Riwayat Parameter (24 Jam)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF111827),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1D9E75)),
            onPressed: () => context.read<SensorProvider>().loadHistory24h(),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensor, _) {
          if (sensor.isLoading24h) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D9E75)),
            );
          }

          if (sensor.history24h.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 48, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada data riwayat',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final dangerCount = sensor.history24h.where(_isDanger).length;

          return Column(
            children: [
              // ── Legend + stats bar ────────────────────────────────────
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                            color: const Color(0xFFE24B4A), width: 1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Di zona bahaya ($dangerCount dari ${sensor.history24h.length} bacaan)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Header tabel ──────────────────────────────────────────
              _TableHeader(),

              // ── Isi tabel ─────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  itemCount: sensor.history24h.length,
                  itemBuilder: (context, index) {
                    final r = sensor.history24h[index];
                    return _TableRow(reading: r);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF6B7280),
    );
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('Waktu', style: style)),
          Expanded(
              flex: 2,
              child: Text('DO', style: style, textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('Suhu', style: style, textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('Sal', style: style, textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('pH', style: style, textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('Status', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

// ─── Data row ─────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final SensorReading reading;
  const _TableRow({required this.reading});

  @override
  Widget build(BuildContext context) {
    final danger = _isDanger(reading);
    final bg = danger ? const Color(0xFFFDE8E8) : Colors.white;

    final timeStr =
        DateFormat('HH:mm\ndd/MM').format(reading.timestamp.toLocal());

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Waktu
          Expanded(
            flex: 3,
            child: Text(
              timeStr,
              style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
            ),
          ),
          // DO
          Expanded(
            flex: 2,
            child: _ValCell(
              label: reading.doLevel.toStringAsFixed(1),
              isDanger: _isBadVal('do', reading.doLevel),
            ),
          ),
          // Suhu
          Expanded(
            flex: 2,
            child: _ValCell(
              label: reading.temperature.toStringAsFixed(1),
              isDanger: _isBadVal('temp', reading.temperature),
            ),
          ),
          // Salinitas
          Expanded(
            flex: 2,
            child: _ValCell(
              label: reading.salinity.toStringAsFixed(1),
              isDanger: _isBadVal('sal', reading.salinity),
            ),
          ),
          // pH
          Expanded(
            flex: 2,
            child: _ValCell(
              label: reading.ph.toStringAsFixed(2),
              isDanger: _isBadVal('ph', reading.ph),
            ),
          ),
          // Status badge
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFFE24B4A).withAlpha(20)
                      : const Color(0xFF1D9E75).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  danger ? 'Bahaya' : 'Normal',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: danger
                        ? const Color(0xFFE24B4A)
                        : const Color(0xFF1D9E75),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValCell extends StatelessWidget {
  final String label;
  final bool isDanger;
  const _ValCell({required this.label, required this.isDanger});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isDanger ? FontWeight.w700 : FontWeight.w500,
          color: isDanger ? const Color(0xFFE24B4A) : const Color(0xFF374151),
        ),
      ),
    );
  }
}
