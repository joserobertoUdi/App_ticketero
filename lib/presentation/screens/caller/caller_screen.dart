import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/settings_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../ticket_selection/widgets/background_video_widget.dart';

class CallerScreen extends StatefulWidget {
  const CallerScreen({super.key});

  @override
  State<CallerScreen> createState() => _CallerScreenState();
}

class _CallerScreenState extends State<CallerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleFullScreen() async {
    try {
      final fs = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!fs);
    } catch (_) {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final kiosko = settings.selectedKiosko;
        final videoUrl = kiosko?.videoUrl;
        final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

        return Scaffold(
          body: Stack(
            children: [
              if (hasVideo)
                SizedBox.expand(
                  child: BackgroundVideoWidget(videoUrl: videoUrl),
                )
              else
                const SizedBox.expand(child: ColoredBox(color: Colors.white)),
              Consumer<TicketProvider>(
                builder: (context, tp, _) {
                  return Column(
                    children: [
                      const Expanded(flex: 2, child: SizedBox.expand()),
                      Expanded(flex: 1, child: _buildBottomPanels(tp)),
                    ],
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) => IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white54, size: 28),
                    tooltip: 'Cerrar sesion',
                    onPressed: () async {
                      auth.logout();
                      if (context.mounted) {
                        try {
                          await Navigator.pushReplacementNamed(context, '/login');
                        } catch (_) {
                          await windowManager.close();
                        }
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black26,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: _toggleFullScreen,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomPanels(TicketProvider tp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _FrostedPanel(
              child: _buildRecentCalls(tp),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _FrostedPanel(
              child: _buildCompactTicket(tp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCalls(TicketProvider tp) {
    final calls = tp.recentCalls;
    final historyPerArea = <int, Set<String>>{};
    for (final h in tp.attentionHistory) {
      if (h.areaId != null) {
        historyPerArea.putIfAbsent(h.areaId!, () => {}).add(h.codigoTicket!);
      }
    }

    final latestPerCodigo = <String, RecentCall>{};
    for (final c in calls) {
      final completedInThisArea = historyPerArea[c.areaId] ?? <String>{};
      if (!completedInThisArea.contains(c.codigoTicket)) {
        final existing = latestPerCodigo[c.codigoTicket];
        if (existing == null || c.calledAt.isAfter(existing.calledAt)) {
          latestPerCodigo[c.codigoTicket] = c;
        }
      }
    }
    final activeKeys = latestPerCodigo.values.map((c) => '${c.areaId}:${c.codigoTicket}').toSet();

    final sorted = List<RecentCall>.from(calls);
    sorted.sort((a, b) {
      final aKey = '${a.areaId}:${a.codigoTicket}';
      final bKey = '${b.areaId}:${b.codigoTicket}';
      final aActive = activeKeys.contains(aKey);
      final bActive = activeKeys.contains(bKey);
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      return b.calledAt.compareTo(a.calledAt);
    });
    final display = sorted.length > 6 ? sorted.sublist(0, 6) : sorted;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('LLAMADOS RECIENTES',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          if (display.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Sin llamados',
                    style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rowHeight = (constraints.maxHeight - 8) / 2;
                  return Column(
                    children: [
                      SizedBox(
                        height: rowHeight,
                        child: Row(
                          children: [
                            for (int i = 0; i < 3 && i < display.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: i > 0 ? 8.0 : 0,
                                    right: i < 2 ? 0 : 0,
                                  ),
                                  child: _buildCallCard(display[i], historyPerArea, activeKeys),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (display.length > 3)
                        SizedBox(
                          height: rowHeight,
                          child: Row(
                            children: [
                              for (int i = 3; i < 6 && i < display.length; i++)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: i > 3 ? 8.0 : 0,
                                      right: i < 5 ? 0 : 0,
                                    ),
                                    child: _buildCallCard(display[i], historyPerArea, activeKeys),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallCard(RecentCall c, Map<int, Set<String>> historyPerArea, Set<String> activeKeys) {
    final completedInThisArea = historyPerArea[c.areaId] ?? <String>{};
    final isCompleted = completedInThisArea.contains(c.codigoTicket);
    final isActive = activeKeys.contains('${c.areaId}:${c.codigoTicket}');
    final isPassed = !isActive && !isCompleted;

    Color cardColor;
    Color textColor;
    if (isActive) {
      cardColor = AppColors.success.withValues(alpha: 0.2);
      textColor = AppColors.success;
    } else if (isCompleted || isPassed) {
      cardColor = AppColors.primary.withValues(alpha: 0.15);
      textColor = AppColors.primary;
    } else {
      cardColor = AppColors.primary.withValues(alpha: 0.12);
      textColor = AppColors.primary;
    }

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final blinkOpacity = isActive
            ? 1.0
            : isCompleted || isPassed
                ? 0.8
                : 0.3 + (_blinkController.value * 0.7);
        return Opacity(
          opacity: blinkOpacity,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              border: isActive ? Border.all(color: AppColors.success, width: 1.5) : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (c.prioridad > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.flash_on, size: 14, color: Colors.orange),
                        ),
                      if (c.derivadoDe != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.swap_horiz, size: 14, color: Colors.orange),
                        ),
                      Text(c.codigoTicket,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 16)),
                    ],
                  ),
                  if (c.puesto != null && c.puesto!.isNotEmpty)
                    Text(c.puesto!,
                        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(_formatTime(c.calledAt),
                      style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactTicket(TicketProvider tp) {
    final ticket = tp.lastCalledTicket;
    final isActive = tp.activeAttention?.codigoTicket == ticket?.codigoTicket;
    bool isCompleted = false;
    if (ticket != null) {
      isCompleted = tp.attentionHistory.any(
        (h) => h.codigoTicket == ticket.codigoTicket && h.areaId == ticket.areaId,
      );
    }

    Color ticketColor = AppColors.primary;
    if (isActive) ticketColor = AppColors.success;
    if (isCompleted) ticketColor = AppColors.primary.withValues(alpha: 0.35);

    return Center(
      child: ticket == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.confirmation_number, size: 40, color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text('Sin ticket',
                    style: TextStyle(color: AppColors.primary.withValues(alpha: 0.4), fontSize: 14)),
              ],
            )
          : AnimatedBuilder(
              animation: _blinkController,
              builder: (context, child) {
                final blinkOpacity = !isActive && !isCompleted
                    ? 0.3 + (_blinkController.value * 0.7)
                    : 1.0;
                return Opacity(
                  opacity: blinkOpacity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (ticket.esPrioritario)
                            Icon(Icons.flash_on, size: 18, color: Colors.orange),
                          if (ticket.derivadoDe != null) ...[
                            Icon(Icons.swap_horiz, size: 18, color: Colors.orange),
                            const SizedBox(width: 4),
                          ],
                          Text('TICKET',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: ticketColor.withValues(alpha: 0.6),
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(ticket.codigoTicket,
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: ticketColor,
                            shadows: [
                              Shadow(
                                color: ticketColor.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          )),
                      const SizedBox(height: 8),
                      if (ticket.derivadoDe != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Derivado de ${ticket.derivadoDeNombre}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600)),
                        ),
                      if (tp.recentCalls.isNotEmpty && tp.recentCalls.first.puesto != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Dirijase a ${tp.recentCalls.first.puesto}',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ticketColor)),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _FrostedPanel extends StatelessWidget {
  final Widget child;
  const _FrostedPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
