import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../repositories/daily_log_repository.dart';
import '../../core/local/preferences.dart';

// ─── Preset tindakan (F2.6 spec) ─────────────────────────────────────────────

const _presets = [
  (key: 'ganti_air', label: 'Ganti air sebagian', icon: Icons.water),
  (key: 'aerator', label: 'Tambah aerator', icon: Icons.air),
  (key: 'probiotik', label: 'Beri probiotik / obat', icon: Icons.medication),
  (key: 'bersihkan', label: 'Bersihkan kolam', icon: Icons.cleaning_services),
  (key: 'panen_parsial', label: 'Panen parsial', icon: Icons.set_meal),
  (
    key: 'ganti_darurat',
    label: 'Pergantian air darurat',
    icon: Icons.emergency
  ),
];

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────

class DailyLogBottomSheet extends StatefulWidget {
  const DailyLogBottomSheet({super.key});

  @override
  State<DailyLogBottomSheet> createState() => _DailyLogBottomSheetState();
}

class _DailyLogBottomSheetState extends State<DailyLogBottomSheet> {
  final Set<String> _selected = {};
  final _notesController = TextEditingController();
  final _repo = DailyLogRepository();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu tindakan.'),
          backgroundColor: Color(0xFFEF9F27),
        ),
      );
      return;
    }

    final farmId = Preferences.activeFarmId;
    if (farmId == null) return;

    setState(() => _isSubmitting = true);

    final log = await _repo.submitLog(
      farmId: farmId,
      actions: _selected.toList(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (log != null) {
      final isOffline = context.read<ConnectivityProvider>().isOffline;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'Catatan disimpan offline. Akan di-sync saat online.'
                : 'Catatan harian berhasil disimpan.',
          ),
          backgroundColor: const Color(0xFF1D9E75),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan. Coba lagi.'),
          backgroundColor: Color(0xFFE24B4A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Judul ───────────────────────────────────────────────────────
          const Text(
            'Catatan Harian',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih tindakan yang dilakukan hari ini',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),

          // ── Preset chips ────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((p) {
              final selected = _selected.contains(p.key);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selected.remove(p.key);
                  } else {
                    _selected.add(p.key);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1D9E75).withAlpha(20)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1D9E75)
                          : Colors.grey.shade200,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.icon,
                        size: 14,
                        color: selected
                            ? const Color(0xFF1D9E75)
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Field catatan ────────────────────────────────────────────────
          TextField(
            controller: _notesController,
            maxLength: 100,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Catatan tambahan (opsional)...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1D9E75),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
              counterStyle: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tombol simpan ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Simpan Catatan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
