import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../utils/alert_actions.dart';

class AlertHistory extends StatefulWidget {
  const AlertHistory({super.key});

  @override
  State<AlertHistory> createState() => _AlertHistoryState();
}

class _AlertHistoryState extends State<AlertHistory> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pastikan polling sudah dimulai (kalau dari HistoryScreen langsung)
      context.read<AlertProvider>().startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading && prov.alerts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1D9E75)),
          );
        }

        if (prov.alerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none,
                    size: 48, color: Color(0xFFD1D5DB)),
                SizedBox(height: 12),
                Text(
                  'Belum ada peringatan',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prov.alerts.length,
          itemBuilder: (context, index) {
            return _AlertCard(alert: prov.alerts[index]);
          },
        );
      },
    );
  }
}

// ─── Alert card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final Alert alert;
  const _AlertCard({required this.alert});

  bool get _isDanger => alert.urgency == 'bahaya';

  Color get _color =>
      _isDanger ? const Color(0xFFE24B4A) : const Color(0xFFEF9F27);

  String get _paramLabel {
    const labels = {
      'do': 'DO',
      'temp': 'Suhu',
      'sal': 'Salinitas',
      'ph': 'pH',
    };
    return labels[alert.parameter] ?? alert.parameter.toUpperCase();
  }

  /// Tindakan dari local map (F3.3) — offline safe.
  String get _action {
    final local = resolveAlertAction(
      alert.parameter,
      alert.urgency,
      value: alert.value,
    );
    return local.isNotEmpty ? local : alert.actionText;
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd MMM yyyy • HH:mm', 'id')
        .format(alert.timestamp.toLocal());

    return Opacity(
      opacity: alert.isRead ? 0.55 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: alert.isRead
            ? null
            : () => context.read<AlertProvider>().markAsRead(alert.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: alert.isRead ? Colors.grey.shade200 : _color.withAlpha(80),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status dot
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: alert.isRead ? Colors.grey.shade300 : _color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),

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
                              color: _color.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _isDanger ? 'BAHAYA' : 'WASPADA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_paramLabel — ${alert.value.toStringAsFixed(alert.parameter == "ph" ? 2 : 1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _action,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
