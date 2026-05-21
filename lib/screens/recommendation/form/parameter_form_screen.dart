import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/recommendation_provider.dart';
import '../../../providers/farm_provider.dart';
import '../../../core/local/preferences.dart';

class ParameterFormScreen extends StatefulWidget {
  const ParameterFormScreen({super.key});

  @override
  State<ParameterFormScreen> createState() => _ParameterFormScreenState();
}

class _ParameterFormScreenState extends State<ParameterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _salCtrl = TextEditingController();
  final _phCtrl = TextEditingController();

  @override
  void dispose() {
    _doCtrl.dispose(); _tempCtrl.dispose(); _salCtrl.dispose(); _phCtrl.dispose();
    super.dispose();
  }

  Color _valColor(double? v, double optMin, double optMax, double warnMin, double warnMax) {
    if (v == null) return Colors.grey.shade400;
    if (v >= optMin && v <= optMax) return const Color(0xFF1D9E75);
    if (v >= warnMin && v <= warnMax) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<RecommendationProvider>();
    provider.setParameterData({
      'do_level': double.parse(_doCtrl.text),
      'temperature': double.parse(_tempCtrl.text),
      'salinity': double.parse(_salCtrl.text),
      'ph': double.parse(_phCtrl.text),
    });

    final farmId = Preferences.activeFarmId ?? context.read<FarmProvider>().currentFarm?.id;
    if (farmId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm tidak ditemukan. Buat siklus tambak terlebih dahulu.'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    final success = await provider.submitRecommendation(farmId);
    if (!mounted) return;

    if (success) {
      Navigator.pushNamed(context, '/recommendation/result');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Terjadi kesalahan.'), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RecommendationProvider>().isLoading;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Parameter Air',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF111827)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  _buildInfoHeader(),
                  const SizedBox(height: 20),
                  _buildParamCard(
                    ctrl: _doCtrl, label: 'DO (Dissolved Oxygen)', unit: 'mg/L', icon: Icons.air,
                    optMin: 5.0, optMax: 8.0, warnMin: 3.0, warnMax: 10.0, min: 1.0, max: 12.0,
                    hint: 'Optimal 5\u20138',
                  ),
                  const SizedBox(height: 12),
                  _buildParamCard(
                    ctrl: _tempCtrl, label: 'Suhu Air', unit: '\u00B0C', icon: Icons.thermostat,
                    optMin: 23.0, optMax: 30.0, warnMin: 20.0, warnMax: 32.0, min: 15.0, max: 38.0,
                    hint: 'Optimal 23\u201330',
                  ),
                  const SizedBox(height: 12),
                  _buildParamCard(
                    ctrl: _salCtrl, label: 'Salinitas', unit: 'ppt', icon: Icons.waves,
                    optMin: 10.0, optMax: 25.0, warnMin: 5.0, warnMax: 35.0, min: 0.0, max: 40.0,
                    hint: 'Optimal 10\u201325',
                  ),
                  const SizedBox(height: 12),
                  _buildParamCard(
                    ctrl: _phCtrl, label: 'pH Air', unit: 'pH', icon: Icons.science,
                    optMin: 7.5, optMax: 8.5, warnMin: 7.0, warnMax: 9.0, min: 6.0, max: 10.0,
                    hint: 'Optimal 7.5\u20138.5',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isLoading),
    );
  }

  // ─── Step indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          _stepItem(1, 'Observasi', done: true),
          _stepLine(filled: true),
          _stepItem(2, 'Parameter', active: true),
          _stepLine(filled: false),
          _stepItem(3, 'Hasil'),
        ],
      ),
    );
  }

  Widget _stepItem(int step, String label, {bool active = false, bool done = false}) {
    final Color color = (active || done) ? const Color(0xFF1D9E75) : const Color(0xFFD1D5DB);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF1D9E75) : done ? const Color(0xFF1D9E75) : Colors.white,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('$step', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: active ? Colors.white : const Color(0xFFD1D5DB))),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
          fontSize: 10,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          color: active ? const Color(0xFF111827) : done ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        )),
      ],
    );
  }

  Widget _stepLine({required bool filled}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        height: 1.5,
        color: filled ? const Color(0xFF1D9E75) : const Color(0xFFE5E7EB),
      ),
    );
  }

  // ─── Info header ───────────────────────────────────────────────────────────

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D9E75).withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D9E75).withAlpha(40)),
      ),
      child: const Row(
        children: [
          Icon(Icons.biotech_outlined, color: Color(0xFF1D9E75), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Masukkan Hasil Pengukuran',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF111827))),
                SizedBox(height: 2),
                Text('Gunakan alat ukur: DO meter, termometer, refraktometer, pH meter',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Parameter card ────────────────────────────────────────────────────────

  Widget _buildParamCard({
    required TextEditingController ctrl,
    required String label, required String unit, required IconData icon,
    required double optMin, required double optMax,
    required double warnMin, required double warnMax,
    required double min, required double max, required String hint,
  }) {
    final val = double.tryParse(ctrl.text);
    final color = _valColor(val, optMin, optMax, warnMin, warnMax);
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
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(6)),
              child: Text(hint, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
            decoration: InputDecoration(
              suffixText: unit,
              suffixStyle: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
              hintText: '0.0',
              hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.grey.shade300),
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '$label wajib diisi';
              final p = double.tryParse(v);
              if (p == null) return 'Masukkan angka valid';
              if (p < min || p > max) return 'Rentang valid: $min \u2013 $max $unit';
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ]),
      ),
    );
  }

  // ─── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : _onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D9E75), foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.psychology, size: 20),
                  SizedBox(width: 8),
                  Text('Dapatkan Rekomendasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
        ),
      ),
    );
  }
}
