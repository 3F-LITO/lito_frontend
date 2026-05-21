import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/local/preferences.dart';
import '../../models/farm.dart';
import '../../providers/farm_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _benitaCtrl = TextEditingController();
  final _kolomCtrl = TextEditingController();

  DateTime? _stockingDate;
  String _shrimpType = 'vannamei';
  bool _submitting = false;
  bool _showCreate = false; // false = pilih farm ada, true = buat baru

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<FarmProvider>().loadAllFarms();
      // Jika tidak ada farm sama sekali, langsung tampilkan form buat baru
      if (mounted && context.read<FarmProvider>().allFarms.isEmpty) {
        setState(() => _showCreate = true);
      }
    });
  }

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
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1D9E75)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _stockingDate = picked);
  }

  Future<void> _selectExisting(Farm farm) async {
    setState(() => _submitting = true);
    await context.read<FarmProvider>().selectFarm(farm);
    if (!mounted) return;
    setState(() => _submitting = false);
    await Preferences.setOnboarded(true);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stockingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal tebar benur terlebih dahulu.')),
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
      await Preferences.setOnboarded(true);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      final err = context.read<FarmProvider>().error ?? 'Gagal menyimpan data.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FarmProvider>();
    final farms = provider.allFarms;
    final hasExisting = farms.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // ── Welcome header ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D9E75).withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF1D9E75).withAlpha(40)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.agriculture,
                              color: Color(0xFF1D9E75), size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang di Lito 👋',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pilih tambak yang sudah ada atau buat siklus baru.',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Toggle pilih / buat baru (hanya jika ada farm) ──
                    if (hasExisting) ...[
                      _ModeToggle(
                        showCreate: _showCreate,
                        onToggle: (v) => setState(() => _showCreate = v),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Konten sesuai mode ────────────────────────────
                    if (!_showCreate && hasExisting)
                      _FarmPickerList(
                        farms: farms,
                        submitting: _submitting,
                        onSelect: _selectExisting,
                      )
                    else
                      _CreateForm(
                        formKey: _formKey,
                        namaCtrl: _namaCtrl,
                        benitaCtrl: _benitaCtrl,
                        kolomCtrl: _kolomCtrl,
                        stockingDate: _stockingDate,
                        shrimpType: _shrimpType,
                        submitting: _submitting,
                        onPickDate: _pickDate,
                        onShrimpChanged: (v) =>
                            setState(() => _shrimpType = v ?? 'vannamei'),
                        onSubmit: _submit,
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Toggle widget ─────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final bool showCreate;
  final ValueChanged<bool> onToggle;
  const _ModeToggle({required this.showCreate, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(
            label: 'Pilih Farm Ada',
            icon: Icons.list_alt_rounded,
            active: !showCreate,
            onTap: () => onToggle(false),
          ),
          _Tab(
            label: 'Buat Siklus Baru',
            icon: Icons.add_circle_outline,
            active: showCreate,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _Tab(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: active
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Farm picker list ──────────────────────────────────────────────────────────
class _FarmPickerList extends StatelessWidget {
  final List<Farm> farms;
  final bool submitting;
  final ValueChanged<Farm> onSelect;
  const _FarmPickerList(
      {required this.farms,
      required this.submitting,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'id');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${farms.length} tambak ditemukan',
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        ...farms.map((farm) {
          final shrimpLabel = farm.shrimpType == 'vannamei'
              ? 'Vannamei'
              : farm.shrimpType == 'windu'
                  ? 'Windu'
                  : farm.shrimpType;
          final doc = DateTime.now().difference(farm.stockingDate).inDays;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.set_meal,
                    color: Color(0xFF1D9E75), size: 22),
              ),
              title: Text(farm.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF111827))),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    '$shrimpLabel · ${farm.sizeM2.toStringAsFixed(0)} m²',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    'Tebar ${fmt.format(farm.stockingDate)} · DOC $doc hari',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              trailing: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1D9E75)))
                  : ElevatedButton(
                      onPressed: () => onSelect(farm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Pilih'),
                    ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Create form ───────────────────────────────────────────────────────────────
class _CreateForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController namaCtrl, benitaCtrl, kolomCtrl;
  final DateTime? stockingDate;
  final String shrimpType;
  final bool submitting;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onShrimpChanged;
  final VoidCallback onSubmit;

  const _CreateForm({
    required this.formKey,
    required this.namaCtrl,
    required this.benitaCtrl,
    required this.kolomCtrl,
    required this.stockingDate,
    required this.shrimpType,
    required this.submitting,
    required this.onPickDate,
    required this.onShrimpChanged,
    required this.onSubmit,
  });

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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nama kolam ────────────────────────────────────────────
          const _Label('Nama Kolam (opsional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: namaCtrl,
            decoration: _decor('Contoh: Kolam A'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // ── Tanggal tebar ─────────────────────────────────────────
          const _Label('Tanggal Tebar Benur *'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onPickDate,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: stockingDate == null
                      ? Colors.grey.shade300
                      : const Color(0xFF1D9E75),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: stockingDate == null
                        ? Colors.grey.shade400
                        : const Color(0xFF1D9E75),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    stockingDate == null
                        ? 'Pilih tanggal tebar'
                        : DateFormat('dd MMMM yyyy', 'id')
                            .format(stockingDate!),
                    style: TextStyle(
                      fontSize: 14,
                      color: stockingDate == null
                          ? Colors.grey.shade400
                          : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Jenis udang ───────────────────────────────────────────
          const _Label('Jenis Udang *'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: shrimpType,
                isExpanded: true,
                onChanged: onShrimpChanged,
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

          // ── Jumlah benur ──────────────────────────────────────────
          const _Label('Jumlah Benur (ekor) *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: benitaCtrl,
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

          // ── Ukuran kolam ──────────────────────────────────────────
          const _Label('Ukuran Kolam (m²) *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: kolomCtrl,
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

          // ── Submit ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text(
                      'Mulai Pantau Tambak',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
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

