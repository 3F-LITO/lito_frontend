import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/recommendation_provider.dart';
import '../../../providers/farm_provider.dart';

class ContextualFormScreen extends StatefulWidget {
  const ContextualFormScreen({super.key});

  @override
  State<ContextualFormScreen> createState() => _ContextualFormScreenState();
}

class _ContextualFormScreenState extends State<ContextualFormScreen> {
  int _waterColor = 0;
  int _shrimpCondition = 0;
  int _appetite = 0;
  int _weather = 0;
  int _pondBottom = 0;
  final _docController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final farm = context.read<FarmProvider>().currentFarm;
      if (farm != null) {
        final days = DateTime.now().difference(farm.stockingDate).inDays + 1;
        _docController.text = days.clamp(1, 365).toString();
      }
    });
  }

  @override
  void dispose() {
    _docController.dispose();
    super.dispose();
  }

  void _onNext() {
    final doc = int.tryParse(_docController.text) ?? 30;
    context.read<RecommendationProvider>().setContextualData({
      'water_color': _waterColor,
      'shrimp_condition': _shrimpCondition,
      'appetite': _appetite,
      'weather': _weather,
      'pond_bottom': _pondBottom,
      'doc': doc.clamp(1, 365),
    });
    Navigator.pushNamed(context, '/recommendation/parameter');
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
          'Observasi Kolam',
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
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                // â”€â”€ Info header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _buildInfoHeader(),
                const SizedBox(height: 20),

                // â”€â”€ DOC â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _buildDocCard(),
                const SizedBox(height: 20),

                // â”€â”€ Category sections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _buildCategoryCard(
                  title: 'Warna Air',
                  subtitle: 'Warna air kolam saat ini',
                  icon: Icons.water_drop_outlined,
                  options: _waterColorOptions,
                  selected: _waterColor,
                  onSelected: (v) => setState(() => _waterColor = v),
                ),
                const SizedBox(height: 12),
                _buildCategoryCard(
                  title: 'Kondisi Udang',
                  subtitle: 'Aktivitas dan perilaku udang',
                  icon: Icons.pest_control,
                  options: _shrimpOptions,
                  selected: _shrimpCondition,
                  onSelected: (v) => setState(() => _shrimpCondition = v),
                ),
                const SizedBox(height: 12),
                _buildCategoryCard(
                  title: 'Nafsu Makan',
                  subtitle: 'Respons udang terhadap pakan',
                  icon: Icons.restaurant_outlined,
                  options: _appetiteOptions,
                  selected: _appetite,
                  onSelected: (v) => setState(() => _appetite = v),
                ),
                const SizedBox(height: 12),
                _buildCategoryCard(
                  title: 'Cuaca',
                  subtitle: 'Kondisi cuaca saat pengukuran',
                  icon: Icons.wb_cloudy_outlined,
                  options: _weatherOptions,
                  selected: _weather,
                  onSelected: (v) => setState(() => _weather = v),
                ),
                const SizedBox(height: 12),
                _buildCategoryCard(
                  title: 'Dasar Kolam',
                  subtitle: 'Kondisi sedimen dasar kolam',
                  icon: Icons.layers_outlined,
                  options: _pondBottomOptions,
                  selected: _pondBottom,
                  onSelected: (v) => setState(() => _pondBottom = v),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // â”€â”€â”€ Step indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          _stepItem(1, 'Observasi', active: true, done: false),
          _stepLine(filled: false),
          _stepItem(2, 'Parameter', active: false, done: false),
          _stepLine(filled: false),
          _stepItem(3, 'Hasil', active: false, done: false),
        ],
      ),
    );
  }

  Widget _stepItem(int step, String label, {required bool active, required bool done}) {
    final Color color = active || done ? const Color(0xFF1D9E75) : const Color(0xFFD1D5DB);
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
                : Text('$step', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFFD1D5DB))),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
          ),
        ),
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

  // â”€â”€â”€ Info header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          Icon(Icons.remove_red_eye_outlined, color: Color(0xFF1D9E75), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Observasi Kondisi Tambak',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF111827)),
                ),
                SizedBox(height: 2),
                Text(
                  'Pilih kondisi yang paling sesuai untuk setiap kategori.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ DOC card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildDocCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1D9E75), size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DOC', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827))),
                  SizedBox(height: 2),
                  Text('Hari ke- sejak tebar benur', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _docController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Category card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_Option> options,
    required int selected,
    required void Function(int) onSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF1D9E75), size: 16),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827))),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 14),
            // Option tiles
            Row(
              children: options.asMap().entries.map((entry) {
                final idx = entry.key;
                final opt = entry.value;
                final isSelected = selected == idx;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelected(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1D9E75).withAlpha(18) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1D9E75) : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            opt.icon,
                            size: 22,
                            color: isSelected ? const Color(0xFF1D9E75) : opt.color,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            opt.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: isSelected ? const Color(0xFF1D9E75) : const Color(0xFF6B7280),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Bottom bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D9E75),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Lanjut ke Parameter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Option data ───────────────────────────────────────────────────────────

  static const _waterColorOptions = [
    _Option('Hijau\nCerah',    Icons.water_drop,              Color(0xFF22C55E)),
    _Option('Hijau\nTua',     Icons.water_drop,              Color(0xFF15803D)),
    _Option('Coklat/\nKuning', Icons.water_drop,             Color(0xFFCA8A04)),
    _Option('Hitam/\nGelap',  Icons.water_drop,              Color(0xFF374151)),
    _Option('Merah\nKeruh',   Icons.water_drop,              Color(0xFFDC2626)),
  ];
  static const _shrimpOptions = [
    _Option('Normal\nAktif',   Icons.sentiment_satisfied_alt, Color(0xFF22C55E)),
    _Option('Kurang\nAktif',   Icons.sentiment_neutral,       Color(0xFFD97706)),
    _Option('Menggantung',     Icons.warning_amber_rounded,   Color(0xFFEA580C)),
    _Option('Mati/\nStres',    Icons.dangerous,               Color(0xFFDC2626)),
  ];
  static const _appetiteOptions = [
    _Option('Lahap',          Icons.restaurant,    Color(0xFF22C55E)),
    _Option('Normal',         Icons.restaurant,    Color(0xFF6B7280)),
    _Option('Berkurang',      Icons.trending_down, Color(0xFFD97706)),
    _Option('Tidak\nMakan',  Icons.block,         Color(0xFFDC2626)),
  ];
  static const _weatherOptions = [
    _Option('Cerah',          Icons.wb_sunny,     Color(0xFFEAB308)),
    _Option('Berawan',        Icons.cloud,        Color(0xFF94A3B8)),
    _Option('Hujan\nRingan',  Icons.grain,        Color(0xFF60A5FA)),
    _Option('Hujan\nDeras',   Icons.thunderstorm, Color(0xFF6366F1)),
  ];
  static const _pondBottomOptions = [
    _Option('Bersih',           Icons.auto_awesome, Color(0xFF22C55E)),
    _Option('Sedikit\nEndapan', Icons.layers,       Color(0xFFD97706)),
    _Option('Banyak\nEndapan',  Icons.layers_clear, Color(0xFFEA580C)),
    _Option('Hitam/\nBerbau',   Icons.warning,      Color(0xFFDC2626)),
  ];
}

class _Option {
  final String label;
  final IconData icon;
  final Color color;
  const _Option(this.label, this.icon, this.color);
}
