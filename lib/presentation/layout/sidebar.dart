import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String route;
  final bool enabled;

  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
    this.enabled = true,
  });
}

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final List<NavItem> items;
  final String footerVentanillas;
  final String footerAreas;
  final String footerSync;
  final bool isOnline;

  const Sidebar({
    super.key,
    required this.currentRoute,
    required this.items,
    this.footerVentanillas = '5',
    this.footerAreas = '3',
    this.footerSync = '--:--',
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 20),
          ...items.map((item) => _NavItemTile(
                item: item,
                isActive: currentRoute == item.route,
              )),
          const Spacer(),
          Container(
            width: 60,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF22C55E) : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: isOnline
                        ? [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TURNOS\nUDI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    height: 1.3,
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

class _NavItemTile extends StatelessWidget {
  final NavItem item;
  final bool isActive;

  const _NavItemTile({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.enabled
          ? () => Navigator.pushReplacementNamed(context, item.route)
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.7),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
