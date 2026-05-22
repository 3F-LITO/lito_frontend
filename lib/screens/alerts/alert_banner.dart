import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../utils/alert_actions.dart';
import '../main_screen.dart';

// ─── Parameter display labels ─────────────────────────────────────────────────

const _paramLabel = {
  'do': 'DO',
  'temp': 'Suhu',
  'sal': 'Salinitas',
  'ph': 'pH',
};

const _paramUnit = {
  'do': 'mg/L',
  'temp': '°C',
  'sal': 'ppt',
  'ph': '',
};

// ─── Public widget ────────────────────────────────────────────────────────────

/// Banner yang muncul di atas dashboard saat ada alert aktif.
/// Tersembunyi (SizedBox.shrink) jika tidak ada alert belum dibaca.
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AlertProvider, ConnectivityProvider>(
      builder: (context, alertProv, connProv, _) {
        // Saat offline: tampilkan banner offline-alert jika ada cache
        if (connProv.isOffline && alertProv.activeAlerts.isEmpty) {
          return const SizedBox.shrink();
        }

        final alert = alertProv.topAlert;
        if (alert == null) return const SizedBox.shrink();

        return _AlertBannerCard(alert: alert);
      },
    );
  }
}

// ─── Banner card ──────────────────────────────────────────────────────────────

class _AlertBannerCard extends StatelessWidget {
  final Alert alert;
  const _AlertBannerCard({required this.alert});

  bool get _isDanger => alert.urgency == 'bahaya';

  Color get _bgColor =>
      _isDanger ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);

  Color get _borderColor =>
      _isDanger ? const Color(0xFFE24B4A) : const Color(0xFFEF9F27);

  Color get _textColor =>
      _isDanger ? const Color(0xFFB91C1C) : const Color(0xFF92400E);

  String get _urgencyLabel => _isDanger ? 'BAHAYA' : 'WASPADA';

  IconData get _icon => _isDanger ? Icons.warning_rounded : Icons.info_rounded;

  String get _paramDisplay {
    final label = _paramLabel[alert.parameter] ?? alert.parameter.toUpperCase();
    final unit = _paramUnit[alert.parameter] ?? '';
    final val = alert.value.toStringAsFixed(
      alert.parameter == 'ph' ? 2 : 1,
    );
    return '$label ${_isDanger ? "Kritis" : "Rendah/Tinggi"} ($val${unit.isNotEmpty ? " $unit" : ""})';
  }

  /// Tindakan dari local map (F3.3) — offline safe, prioritas di atas server.
  String get _actionText {
    final local = resolveAlertAction(
      alert.parameter,
      alert.urgency,
      value: alert.value,
    );
    return local.isNotEmpty ? local : alert.actionText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            // ── Header row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _borderColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, size: 18, color: _borderColor),
                  ),
                  const SizedBox(width: 10),

                  // Title + action text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _borderColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _urgencyLabel,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '— $_paramDisplay',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _actionText,
                          style: TextStyle(
                            fontSize: 12,
                            color: _textColor.withAlpha(200),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Action row ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: _borderColor.withAlpha(60)),
                ),
              ),
              child: Row(
                children: [
                  // Dismiss button
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          context.read<AlertProvider>().markAsRead(alert.id),
                      style: TextButton.styleFrom(
                        foregroundColor: _textColor.withAlpha(160),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 36,
                    color: _borderColor.withAlpha(60),
                  ),

                  // Detail button
                  Expanded(
                    child: TextButton(
                      onPressed: () => MainScreenController.switchTab(1),
                      style: TextButton.styleFrom(
                        foregroundColor: _borderColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(14),
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lihat Detail',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
