import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/recommendation_provider.dart';
import '../../../models/recommendation.dart';
import 'feed_log_bottom_sheet.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  static const _colors = {
    'AMAN': Color(0xFF1D9E75),
    'WASPADA': Color(0xFFD97706),
    'BAHAYA': Color(0xFFDC2626),
  };
  static const _icons = {
    'AMAN': Icons.check_circle,
    'WASPADA': Icons.warning_amber_rounded,
    'BAHAYA': Icons.dangerous,
  };

  Color _priorityColor(String p) => _colors[p] ?? const Color(0xFF6B8C7A);
  IconData _priorityIcon(String p) => _icons[p] ?? Icons.help_outline;

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>().lastResult;
    if (rec == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Rekomendasi'), backgroundColor: const Color(0xFF1D9E75), foregroundColor: Colors.white),
        body: const Center(child: Text('Tidak ada data rekomendasi')),
      );
    }
    final color = _priorityColor(rec.priority);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Hasil Rekomendasi'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildPriorityBanner(rec, color),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainActionCard(rec, color),
                const SizedBox(height: 14),
                _buildFeedDoseCard(rec, color),
                const SizedBox(height: 14),
                if (rec.feedDoseKg > 0) _buildFeedLogButton(context, rec),
                if (rec.feedDoseKg > 0) const SizedBox(height: 14),
                _buildActionsCard(rec, color),
                const SizedBox(height: 14),
                _buildShapCard(rec),
                const SizedBox(height: 14),
                _buildInputSummary(rec),
                const SizedBox(height: 24),
                _buildBackButton(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBanner(Recommendation rec, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withAlpha(178)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        children: [
          Icon(_priorityIcon(rec.priority), color: Colors.white, size: 52),
          const SizedBox(height: 10),
          Text(rec.priority, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(rec.explanation, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 16),
          // Confidence bar
          Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Kepercayaan Model', style: TextStyle(fontSize: 12, color: Colors.white70)),
                Text('${(rec.confidence * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rec.confidence,
                  minHeight: 8,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedLogButton(BuildContext context, Recommendation rec) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => FeedLogBottomSheet(recommendedKg: rec.feedDoseKg),
        ),
        icon: const Icon(Icons.set_meal, color: Color(0xFF1D9E75), size: 18),
        label: const Text(
          'Catat Realisasi Pakan',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1D9E75)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMainActionCard(Recommendation rec, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.bolt, color: color, size: 20),
              const SizedBox(width: 8),
              const Text('Tindakan Utama',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            ]),
            const SizedBox(height: 8),
            Text(rec.mainAction,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ]),
        ),
      ),
    );
  }

  Widget _buildFeedDoseCard(Recommendation rec, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.set_meal, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Dosis Pakan',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                rec.feedDoseKg == 0 ? 'TUNDA' : '${rec.feedDoseKg.toStringAsFixed(2)} kg',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color),
              ),
              if (rec.feedDoseKg > 0) ...[
                const SizedBox(width: 6),
                const Padding(padding: EdgeInsets.only(bottom: 4),
                    child: Text('per pakan', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
              ],
            ]),
            Text(
              rec.priority == 'BAHAYA' ? 'Hentikan pakan \u2014 kondisi kritis!'
                  : rec.priority == 'WASPADA' ? 'Dikurangi 30% karena kondisi waspada'
                  : 'Dosis normal berdasarkan DOC ${rec.doc}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _buildActionsCard(Recommendation rec, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.checklist, color: color, size: 20),
            const SizedBox(width: 8),
            const Text('Langkah Tindakan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 12),
          ...rec.actions.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
                child: Center(child: Text('${e.key + 1}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.4))),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildShapCard(Recommendation rec) {
    if (rec.shapTop3.isEmpty) return const SizedBox.shrink();
    final maxVal = rec.shapTop3.values.map((v) => (v as num).abs()).reduce((a, b) => a > b ? a : b);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.bar_chart, color: Color(0xFF1D9E75), size: 20),
            SizedBox(width: 8),
            Text('Faktor Penentu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 4),
          const Text('Fitur paling berpengaruh pada prediksi model',
              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 14),
          ...rec.shapTop3.entries.map((e) {
            final val = (e.value as num).toDouble().abs();
            final ratio = maxVal > 0 ? val / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(e.key, style: const TextStyle(fontSize: 13, color: Color(0xFF111827))),
                  Text(val.toStringAsFixed(4),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio, minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D9E75)),
                  ),
                ),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildInputSummary(Recommendation rec) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          leading: const Icon(Icons.info_outline, color: Color(0xFF6B7280)),
          title: const Text('Ringkasan Input',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: [
                _summaryRow('DO', '${rec.doLevel} mg/L'),
                _summaryRow('Suhu', '${rec.temperature}\u00B0C'),
                _summaryRow('Salinitas', '${rec.salinity} ppt'),
                _summaryRow('pH', '${rec.ph}'),
                _summaryRow('DOC', '${rec.doc} hari'),
                const SizedBox(height: 8),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      ]),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
        icon: const Icon(Icons.home_outlined, color: Color(0xFF1D9E75)),
        label: const Text('Kembali ke Dashboard',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1D9E75))),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
