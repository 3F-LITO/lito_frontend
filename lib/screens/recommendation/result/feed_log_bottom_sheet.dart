import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/local/database_helper.dart';
import '../../../core/local/preferences.dart';
import '../../../models/feed_log.dart';
import '../../../providers/farm_provider.dart';

class FeedLogBottomSheet extends StatefulWidget {
  final double recommendedKg;

  const FeedLogBottomSheet({super.key, required this.recommendedKg});

  @override
  State<FeedLogBottomSheet> createState() => _FeedLogBottomSheetState();
}

class _FeedLogBottomSheetState extends State<FeedLogBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  bool _saved = false;

  double get _actualKg =>
      double.tryParse(_actualCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _pricePerKg =>
      double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _totalCost => _actualKg * _pricePerKg;
  bool get _isOverfeeding =>
      widget.recommendedKg > 0 && _actualKg > widget.recommendedKg * 1.2;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final farmId = context.read<FarmProvider>().currentFarm?.id ??
        Preferences.activeFarmId ??
        '';

    final log = FeedLog(
      id: const Uuid().v4(),
      farmId: farmId,
      timestamp: DateTime.now(),
      recommendedKg: widget.recommendedKg,
      actualKg: _actualKg,
      pricePerKg: _pricePerKg,
      notes: _notesCtrl.text.trim(),
    );

    await DatabaseHelper.instance.insertFeedLog(log.toMap());

    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });

    if (_isOverfeeding) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Overfeeding! Realisasi (${_actualKg.toStringAsFixed(2)} kg) '
                'melebihi rekomendasi (${widget.recommendedKg.toStringAsFixed(2)} kg) lebih dari 20%.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ]),
          backgroundColor: const Color(0xFFD97706),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            Row(children: [
              const Icon(Icons.set_meal, color: Color(0xFF1D9E75), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Catat Realisasi Pakan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'Rekomendasi ML: ${widget.recommendedKg.toStringAsFixed(2)} kg/sesi',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),

            // ── Actual kg ─────────────────────────────────────────
            const _Label('Jumlah Pakan Aktual (kg) *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _actualCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              decoration: _decor('cth. 12.5'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final n =
                    double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Masukkan angka > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ── Overfeeding warning (live) ────────────────────────
            if (_actualCtrl.text.isNotEmpty && _isOverfeeding)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD97706)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Melebihi rekomendasi >20% — potensi overfeeding!',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ]),
              ),

            // ── Price per kg ──────────────────────────────────────
            const _Label('Harga Pakan per kg (Rp) *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decor('cth. 15000'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Masukkan harga > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ── Notes ─────────────────────────────────────────────
            const _Label('Catatan (opsional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesCtrl,
              decoration: _decor('cth. Pakan sesi pagi'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // ── Cost preview ──────────────────────────────────────
            if (_actualKg > 0 && _pricePerKg > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF1D9E75).withAlpha(40)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Biaya sesi ini',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF374151))),
                      Text(
                        'Rp ${_totalCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D9E75),
                        ),
                      ),
                    ]),
              ),

            // ── Submit ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving || _saved ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _saved ? 'Tersimpan ✓' : 'Simpan Realisasi Pakan',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
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
        hintStyle:
            const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF1D9E75), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE24B4A))),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      );
}

