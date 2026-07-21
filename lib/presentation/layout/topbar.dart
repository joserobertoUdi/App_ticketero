import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_sync_service.dart';

class TabOption {
  final String label;
  final String value;

  const TabOption({required this.label, required this.value});
}

class TopBar extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<TabOption>? tabs;
  final String? activeTab;
  final ValueChanged<String>? onTabChanged;

  const TopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.tabs,
    this.activeTab,
    this.onTabChanged,
  });

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  String _timeString = '';
  String _dateString = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
  }

  void _updateDateTime() {
    try {
      final sync = Provider.of<TimeSyncService>(context, listen: false);
      if (mounted) {
        setState(() {
          _timeString = sync.formatServerTime();
          _dateString = sync.formatServerDate();
        });
      }
    } catch (_) {
      final now = DateTime.now();
      final time =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';
      final days = [
        'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
      ];
      final months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      final date =
          '${days[now.weekday - 1]} ${now.day} de ${months[now.month - 1]} de ${now.year}';
      _timeString = time;
      _dateString = date;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 54,
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            alignment: Alignment.center,
            child: Text(
              'UDI',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              if (widget.subtitle != null)
                Text(widget.subtitle!,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          if (widget.tabs != null && widget.tabs!.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: widget.tabs!.map((tab) {
                  final isActive = tab.value == widget.activeTab;
                  return GestureDetector(
                    onTap: isActive
                        ? null
                        : () => widget.onTabChanged?.call(tab.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 20),
          ],
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_timeString,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                Text(_dateString,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
