import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/local/preferences.dart';
import '../../providers/farm_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/alert_provider.dart';
import '../../utils/cycle_calculator.dart';
import 'widgets/parameter_card.dart';
import 'widgets/pond_health_score.dart';
import 'widgets/offline_banner.dart';
import '../alerts/alert_banner.dart';
import 'widgets/urgency_label.dart';
import '../main_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Mulai polling setelah widget pertama kali dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final farmId = Preferences.activeFarmId;
      if (farmId != null && mounted) {
        context.read<SensorProvider>().startPolling(farmId);
        context.read<AlertProvider>().startPolling();
      }
      if (mounted) context.read<FarmProvider>().loadCurrentFarm();
    });
  }

  @override
  void dispose() {
    context.read<SensorProvider>().stopPolling();
    context.read<AlertProvider>().stopPolling();
    super.dispose();
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
          'Dashboard Tambak',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          Consumer<SensorProvider>(
            builder: (_, sensor, __) {
              return Consumer<ConnectivityProvider>(
                builder: (_, conn, __) {
                  final isOffline = conn.isOffline;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOffline
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOffline)
                            const Icon(Icons.wifi_off,
                                size: 11, color: Color(0xFFD97706)),
                          if (!isOffline)
                            const Icon(Icons.wifi,
                                size: 11, color: Color(0xFF1D9E75)),
                          const SizedBox(width: 4),
                          Text(
                            isOffline ? 'OFFLINE' : 'ONLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isOffline
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF1D9E75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Consumer2<SensorProvider, ConnectivityProvider>(
        builder: (context, sensor, conn, _) {
          final isOffline = conn.isOffline || sensor.isOffline;

          return Column(
            children: [
              // ── Offline banner ──────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isOffline
                    ? OfflineBanner(
                        key: const ValueKey('offline'),
                        cachedAt: sensor.latest?.timestamp,
                      )
                    : const SizedBox.shrink(key: ValueKey('online')),
              ),

              // ── Main content ────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF1D9E75),
                  onRefresh: () async {
                    final farmId = Preferences.activeFarmId;
                    if (farmId != null) {
                      sensor.startPolling(farmId);
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Alert banner (kritis)
                        const AlertBanner(),

                        // Skor kesehatan kolam
                        PondHealthScore(
                          reading: sensor.latest,
                          isOffline: isOffline,
                        ),
                        const SizedBox(height: 12),

                        // Label status urgensi (F3.2)
                        const UrgencyLabel(),
                        const SizedBox(height: 16),

                        // Ringkasan siklus aktif (F4.2–F4.4)
                        Consumer<FarmProvider>(
                          builder: (_, farmProv, __) {
                            if (farmProv.currentFarm == null) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: [
                                _CycleSummaryCard(farm: farmProv.currentFarm!),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        ),

                        // Tombol cek rekomendasi
                        _QuickActionButton(
                          onTap: () => Navigator.pushNamed(
                              context, '/recommendation/contextual'),
                        ),
                        const SizedBox(height: 20),

                        // ── Header seksi parameter ────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Parameter Real-Time',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            if (sensor.isLoading)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Grid kartu parameter ──────────────────────────
                        ParameterCardsGrid(
                          latest: sensor.latest,
                          baseline: sensor.baseline,
                          history: sensor.history,
                          isOffline: isOffline,
                        ),
                        const SizedBox(height: 12),

                        // ── Tombol riwayat parameter 24 jam (F2.4) ────────
                        _HistoryLinkButton(
                          onTap: () => Navigator.pushNamed(
                              context, '/history/parameters'),
                        ),
                        const SizedBox(height: 8),

                        // ── Tombol riwayat peringatan (F3.4) ──────────────
                        _AlertHistoryLinkButton(
                          onTap: () => MainScreenController.switchTab(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Quick action button ──────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1D9E75), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D9E75).withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.water_drop,
                  size: 22, color: Color(0xFF1D9E75)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cek Kondisi Kolam',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'MULAI ANALISIS AI BARU',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── History link button ──────────────────────────────────────────────────────

class _HistoryLinkButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HistoryLinkButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.history, size: 16, color: Color(0xFF1D9E75)),
            const SizedBox(width: 8),
            const Text(
              'Lihat Riwayat Parameter (24 Jam)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D9E75),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─── Alert history link button (F3.4) — badge unread ─────────────────────────

class _AlertHistoryLinkButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AlertHistoryLinkButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertProvider>(
      builder: (_, alertProv, __) {
        final unread = alertProv.activeAlerts.length;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: unread > 0 ? const Color(0xFFFEF2F2) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: unread > 0
                    ? const Color(0xFFE24B4A).withAlpha(60)
                    : Colors.grey.shade100,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 16,
                  color: unread > 0
                      ? const Color(0xFFE24B4A)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Text(
                  'Riwayat Peringatan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: unread > 0
                        ? const Color(0xFFE24B4A)
                        : const Color(0xFF6B7280),
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE24B4A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread belum dibaca',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Cycle summary card (F4.2–F4.4) ──────────────────────────────────────────

class _CycleSummaryCard extends StatelessWidget {
  final farm;
  const _CycleSummaryCard({required this.farm});

  @override
  Widget build(BuildContext context) {
    final doc = calculateDOC(farm.stockingDate);
    final phase = getPhaseLabel(doc);
    final duration = cycleDuration(farm.shrimpType);
    final progress = cycleProgress(doc, farm.shrimpType);
    final weight = estimateWeight(doc);
    final weightStr =
        weight >= 10 ? weight.toStringAsFixed(0) : weight.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.agriculture, size: 14, color: Color(0xFF1D9E75)),
              const SizedBox(width: 6),
              const Text(
                'Siklus Aktif',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => MainScreenController.switchTab(2),
                child: const Row(
                  children: [
                    Text(
                      'Detail',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D9E75),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right,
                        size: 14, color: Color(0xFF1D9E75)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Stats row ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // DOC big number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$doc',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D9E75),
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'Hari ke-',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(width: 16),
              // Phase + weight chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatChip(
                      icon: Icons.flag_outlined,
                      label: 'Fase $phase',
                      color: const Color(0xFF1D9E75),
                    ),
                    const SizedBox(height: 6),
                    _StatChip(
                      icon: Icons.set_meal,
                      label: '~$weightStr gram',
                      color: const Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Mini progress bar ────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1D9E75),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hari 1',
                style: TextStyle(fontSize: 9, color: Color(0xFFD1D5DB)),
              ),
              Text(
                'Hari $doc dari $duration',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Hari $duration',
                style: const TextStyle(fontSize: 9, color: Color(0xFFD1D5DB)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
