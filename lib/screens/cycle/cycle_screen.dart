import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/local/database_helper.dart';
import '../../core/network/dio_client.dart';
import '../../models/farm.dart';
import '../../models/feed_log.dart';
import '../../providers/farm_provider.dart';
import '../../utils/cycle_calculator.dart';

class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmProvider>().loadCurrentFarm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmProvider>(
      builder: (context, farm, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: const Text(
              'Siklus Budidaya',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF111827),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),
          ),
          body: farm.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1D9E75),
                  ),
                )
              : farm.currentFarm == null
                  ? _InputForm(onCreated: () => setState(() {}))
                  : _CycleInfo(farm: farm.currentFarm!),
        );
      },
    );
  }
}

// ─── Form Input Data Tebar (F4.1) ────────────────────────────────────────────

class _InputForm extends StatefulWidget {
  final VoidCallback onCreated;
  const _InputForm({required this.onCreated});

  @override
  State<_InputForm> createState() => _InputFormState();
}

class _InputFormState extends State<_InputForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _benitaCtrl = TextEditingController();
  final _kolomCtrl = TextEditingController();

  DateTime? _stockingDate;
  String _shrimpType = 'vannamei';
  bool _submitting = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _benitaCtrl.dispose();
    _kolomCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // tidak boleh masa depan
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1D9E75),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _stockingDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stockingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih tanggal tebar benur terlebih dahulu.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final ok = await context.read<FarmProvider>().createFarm(
          name: _namaCtrl.text.trim().isEmpty
              ? 'Kolam ${DateFormat('dd MMM yyyy', 'id').format(_stockingDate!)}'
              : _namaCtrl.text.trim(),
          sizeM2: double.parse(_kolomCtrl.text.replaceAll(',', '.')),
          shrimpType: _shrimpType,
          stockingDate: _stockingDate!,
          stockingCount: int.parse(_benitaCtrl.text.replaceAll('.', '')),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Siklus baru berhasil dibuat!'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      widget.onCreated();
    } else {
      final err = context.read<FarmProvider>().error ?? 'Gagal menyimpan data.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF1D9E75).withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.agriculture, color: Color(0xFF1D9E75), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Input Data Tebar',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Isi data untuk memulai siklus budidaya baru.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Nama kolam (opsional) ────────────────────────────────────
            _Label('Nama Kolam (opsional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _namaCtrl,
              decoration: _decor('Contoh: Kolam A'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ── Tanggal tebar ────────────────────────────────────────────
            _Label('Tanggal Tebar Benur *'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _stockingDate == null
                        ? Colors.grey.shade300
                        : const Color(0xFF1D9E75),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _stockingDate == null
                          ? Colors.grey.shade400
                          : const Color(0xFF1D9E75),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _stockingDate == null
                          ? 'Pilih tanggal tebar'
                          : DateFormat('dd MMMM yyyy', 'id')
                              .format(_stockingDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color: _stockingDate == null
                            ? Colors.grey.shade400
                            : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Jenis udang ──────────────────────────────────────────────
            _Label('Jenis Udang *'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _shrimpType,
                  isExpanded: true,
                  onChanged: (v) =>
                      setState(() => _shrimpType = v ?? 'vannamei'),
                  items: const [
                    DropdownMenuItem(
                        value: 'vannamei',
                        child: Text('Vannamei (L. vannamei)')),
                    DropdownMenuItem(
                        value: 'windu', child: Text('Windu (P. monodon)')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Jumlah benur ─────────────────────────────────────────────
            _Label('Jumlah Benur (ekor) *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _benitaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decor('1.000 – 1.000.000 ekor'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final n = int.tryParse(v.replaceAll('.', ''));
                if (n == null || n < 1000 || n > 1000000) {
                  return 'Masukkan angka antara 1.000 dan 1.000.000';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Ukuran kolam ─────────────────────────────────────────────
            _Label('Ukuran Kolam (m²) *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _kolomCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: _decor('10 – 10.000 m²'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n < 10 || n > 10000) {
                  return 'Masukkan angka antara 10 dan 10.000';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // ── Submit button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Mulai Siklus',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE24B4A)),
        ),
      );
}

// ─── Cycle info view ──────────────────────────────────────────────────────────

class _CycleInfo extends StatelessWidget {
  final Farm farm;
  const _CycleInfo({required this.farm});

  String get _shrimpLabel =>
      farm.shrimpType == 'vannamei' ? 'Vannamei' : 'Windu';

  @override
  Widget build(BuildContext context) {
    final doc = calculateDOC(farm.stockingDate);
    final dateStr = DateFormat('dd MMMM yyyy', 'id').format(farm.stockingDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── DOC Card ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D9E75), Color(0xFF17A589)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hari ke-',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$doc',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const Text(
                  'DOC (Days of Culture)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoPill(icon: Icons.set_meal, label: _shrimpLabel),
                    const SizedBox(width: 8),
                    _InfoPill(icon: Icons.calendar_today, label: dateStr),
                    const SizedBox(width: 8),
                    _InfoPill(
                      icon: Icons.flag,
                      label: 'Fase: ${getPhaseLabel(doc)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Progress Bar (F4.3) ───────────────────────────────────────
          _CycleProgressBar(doc: doc, shrimpType: farm.shrimpType),
          const SizedBox(height: 16),

          // ── Detail cards ──────────────────────────────────────────────
          _DetailCard(
            icon: Icons.water,
            label: 'Ukuran Kolam',
            value: '${farm.sizeM2.toStringAsFixed(0)} m²',
          ),
          const SizedBox(height: 10),
          _DetailCard(
            icon: Icons.egg_alt,
            label: 'Jumlah Benur Tebar',
            value:
                '${NumberFormat('#,###', 'id').format(farm.stockingCount)} ekor',
          ),
          const SizedBox(height: 10),
          _DetailCard(
            icon: Icons.calculate,
            label: 'Kepadatan Tebar',
            value:
                '${(farm.stockingCount / farm.sizeM2).toStringAsFixed(0)} ekor/m²',
          ),
          const SizedBox(height: 16),

          // ── Estimasi Berat (F4.4) ─────────────────────────────────────
          _WeightEstimateCard(doc: doc), const SizedBox(height: 16),

          // ── Estimasi Biaya Pakan (F1.9) ────────────────────────────────
          _FeedCostCard(farmId: farm.id, stockingDate: farm.stockingDate),
          const SizedBox(height: 32),

          // ── Mulai Siklus Baru ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmReset(context),
              icon:
                  const Icon(Icons.refresh, size: 18, color: Color(0xFFE24B4A)),
              label: const Text(
                'Mulai Siklus Baru',
                style: TextStyle(
                  color: Color(0xFFE24B4A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFE24B4A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Mulai Siklus Baru?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: const Text(
          'Data siklus saat ini akan diarsipkan. '
          'Kamu perlu mengisi data tebar baru untuk melanjutkan.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FarmProvider>().resetCycle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE24B4A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ya, Reset',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Weight Estimate Card (F4.4) ────────────────────────────────────────────

class _WeightEstimateCard extends StatelessWidget {
  final int doc;
  const _WeightEstimateCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final weight = estimateWeight(doc);
    final phase = getPhaseLabel(doc);
    final weightStr =
        weight >= 10 ? weight.toStringAsFixed(0) : weight.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D9E75).withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D9E75).withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🦐', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text(
                'Estimasi berat udang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '~$weightStr gram',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1D9E75),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'DOC $doc · Fase $phase',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Estimasi ini menggunakan kondisi budidaya intensif standar. '
            'Berat aktual di lapangan dapat berbeda ±20–30% tergantung kondisi spesifik tambak.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Bar (F4.3) ──────────────────────────────────────────────────────

class _CycleProgressBar extends StatelessWidget {
  final int doc;
  final String shrimpType;
  const _CycleProgressBar({required this.doc, required this.shrimpType});

  @override
  Widget build(BuildContext context) {
    final duration = cycleDuration(shrimpType);
    final progress = cycleProgress(doc, shrimpType);
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Siklus',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final dotX = (w * progress).clamp(0.0, w);

              return Column(
                children: [
                  // ── Top labels: Tebar | Sekarang (X%) | Estimasi Panen ──
                  SizedBox(
                    height: 18,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(
                          left: 0,
                          child: Text(
                            'Tebar',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          left: (dotX - 45).clamp(0.0, (w - 90).clamp(0.0, w)),
                          child: Text(
                            'Sekarang ($pct%)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF1D9E75),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 0,
                          child: Text(
                            'Estimasi Panen',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Track + dot ───────────────────────────────────────────
                  SizedBox(
                    height: 20,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned.fill(
                          top: 7,
                          bottom: 7,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1D9E75),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: (dotX - 8).clamp(0.0, w - 16),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D9E75),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1D9E75).withAlpha(80),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Bottom day labels: Hari 1 | Hari X | Hari N ──────────
                  SizedBox(
                    height: 18,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(
                          left: 0,
                          child: Text(
                            'Hari 1',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        Positioned(
                          left: (dotX - 22).clamp(0.0, (w - 44).clamp(0.0, w)),
                          child: Text(
                            'Hari $doc',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF1D9E75),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: Text(
                            'Hari $duration',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Phase badge ───────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D9E75).withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Fase: ${getPhaseLabel(doc)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1D9E75),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1D9E75)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feed Cost Estimate Card (F1.9) ────────────────────────────────────────────────────

class _FeedCostCard extends StatefulWidget {
  final String farmId;
  final DateTime stockingDate;
  const _FeedCostCard({required this.farmId, required this.stockingDate});

  @override
  State<_FeedCostCard> createState() => _FeedCostCardState();
}

class _FeedCostCardState extends State<_FeedCostCard> {
  late Future<_CostResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _compute();
  }

  @override
  void didUpdateWidget(covariant _FeedCostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recompute when parent rebuilds so new feed logs are reflected.
    _future = _compute();
  }

  Future<_CostResult> _compute() async {
    // Primary source: API (works on web and mobile).
    try {
      final resp = await DioClient.instance.get('/feed-cost/${widget.farmId}/');
      if (resp.statusCode == 200 && resp.data != null) {
        final d = resp.data as Map<String, dynamic>;
        final cost = d['total_cost'] != null
            ? (d['total_cost'] as num).toDouble()
            : null;
        return _CostResult(
          totalCost: cost,
          daysWithPrice: (d['sessions_with_price'] as num? ?? 0).toInt(),
          totalSessions: (d['total_sessions'] as num? ?? 0).toInt(),
        );
      }
    } catch (_) {}

    // Fallback source for mobile offline scenario.
    if (kIsWeb) {
      return const _CostResult(
        totalCost: null,
        daysWithPrice: 0,
        totalSessions: 0,
      );
    }

    final rows = await DatabaseHelper.instance.getFeedLogs(widget.farmId);
    final stockingMidnight = DateTime(
      widget.stockingDate.year,
      widget.stockingDate.month,
      widget.stockingDate.day,
    );
    final relevant = rows
        .map((r) => FeedLog.fromMap(r))
        .where((l) => !l.timestamp.isBefore(stockingMidnight))
        .toList();
    final withPrice = relevant.where((l) => l.pricePerKg > 0).toList();
    if (withPrice.isEmpty) {
      return _CostResult(
          totalCost: null, daysWithPrice: 0, totalSessions: relevant.length);
    }
    final total =
        withPrice.fold(0.0, (sum, l) => sum + l.actualKg * l.pricePerKg);
    return _CostResult(
      totalCost: total,
      daysWithPrice: withPrice.length,
      totalSessions: relevant.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CostResult>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final result = snapshot.data!;
        final hasCost = result.totalCost != null;
        final formatter = NumberFormat.currency(
          locale: 'id',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasCost ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasCost
                  ? const Color(0xFF1D9E75).withAlpha(60)
                  : Colors.grey.shade100,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('💰', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'Estimasi Total Biaya Pakan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (hasCost) ...[
                Text(
                  formatter.format(result.totalCost),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1D9E75),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Berdasarkan ${result.daysWithPrice} dari ${result.totalSessions} sesi dengan harga yang dicatat',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Text(
                  result.totalSessions == 0
                      ? 'Belum ada catatan pakan untuk siklus ini.'
                      : 'Tambahkan harga pakan di "Catat Pakan" untuk melihat estimasi biaya.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CostResult {
  final double? totalCost;
  final int daysWithPrice;
  final int totalSessions;
  const _CostResult({
    required this.totalCost,
    required this.daysWithPrice,
    required this.totalSessions,
  });
}
