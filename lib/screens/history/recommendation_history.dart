import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/local/database_helper.dart';
import '../../core/local/preferences.dart';
import '../../models/recommendation.dart';
import '../../providers/recommendation_provider.dart';

class RecommendationHistory extends StatefulWidget {
  const RecommendationHistory({super.key});

  @override
  State<RecommendationHistory> createState() => _RecommendationHistoryState();
}

class _RecommendationHistoryState extends State<RecommendationHistory> {
  double _totalFeedCost = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationProvider>().loadHistory();
      _loadTotalCost();
    });
  }

  Future<void> _loadTotalCost() async {
    if (kIsWeb) return; // sqflite tidak support web
    final farmId = Preferences.activeFarmId;
    if (farmId == null) return;
    final total = await DatabaseHelper.instance.getTotalFeedCost(farmId);
    if (mounted) setState(() => _totalFeedCost = total);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecommendationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1D9E75)),
          );
        }

        if (provider.history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.science_outlined,
                    size: 48, color: Color(0xFFD1D5DB)),
                SizedBox(height: 12),
                Text(
                  'Belum ada riwayat rekomendasi',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Lakukan analisis AI untuk melihat hasilnya di sini.',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFF1D9E75),
          onRefresh: () async {
            await context.read<RecommendationProvider>().loadHistory();
            await _loadTotalCost();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.history.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCostBanner();
              }
              return _RecommendationCard(rec: provider.history[index - 1]);
            },
          ),
        );
      },
    );
  }

  Widget _buildCostBanner() {
    if (_totalFeedCost <= 0) return const SizedBox.shrink();
    final formatted = _totalFeedCost.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D9E75).withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1D9E75).withAlpha(40)),
      ),
      child: Row(children: [
        const Icon(Icons.payments_outlined, color: Color(0xFF1D9E75), size: 22),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Total Estimasi Biaya Pakan Siklus',
            style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
        ),
        Text(
          'Rp $formatted',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D9E75),
          ),
        ),
      ]),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final Recommendation rec;
  const _RecommendationCard({required this.rec});

  Color get _priorityColor => switch (rec.priority.toLowerCase()) {
        'high' || 'tinggi' => const Color(0xFFE24B4A),
        'medium' || 'sedang' => const Color(0xFFEF9F27),
        _ => const Color(0xFF1D9E75),
      };

  String get _priorityLabel => switch (rec.priority.toLowerCase()) {
        'high' || 'tinggi' => 'TINGGI',
        'medium' || 'sedang' => 'SEDANG',
        _ => 'RENDAH',
      };

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd MMM yyyy • HH:mm', 'id').format(
      rec.timestamp.toLocal(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _priorityColor.withAlpha(12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rec.mainAction,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _priorityLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _priorityColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waktu
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(rec.confidence * 100).toStringAsFixed(0)}% keyakinan',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Sensor snapshot
                _SensorSnapshot(rec: rec),
                const SizedBox(height: 10),

                // Penjelasan
                if (rec.explanation.isNotEmpty)
                  Text(
                    rec.explanation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (rec.actions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        rec.actions.map((a) => _ActionChip(label: a)).toList(),
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

class _SensorSnapshot extends StatelessWidget {
  final Recommendation rec;
  const _SensorSnapshot({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _Pill(label: 'DO', value: '${rec.doLevel.toStringAsFixed(1)} mg/L'),
        _Pill(label: 'T°', value: '${rec.temperature.toStringAsFixed(1)}°C'),
        _Pill(label: 'Sal', value: '${rec.salinity.toStringAsFixed(1)} ppt'),
        _Pill(label: 'pH', value: rec.ph.toStringAsFixed(2)),
        _Pill(label: 'Pakan', value: '${rec.feedDoseKg.toStringAsFixed(2)} kg'),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  const _ActionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1D9E75).withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF1D9E75),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
