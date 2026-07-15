import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'sidebar.dart';
import 'topbar.dart';

class AppShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final String currentRoute;
  final List<TabOption>? tabs;
  final String? activeTab;
  final ValueChanged<String>? onTabChanged;
  final List<NavItem>? extraNavItems;

  const AppShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    required this.currentRoute,
    this.tabs,
    this.activeTab,
    this.onTabChanged,
    this.extraNavItems,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final navItems = _buildNavItems(auth, user);

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            currentRoute: currentRoute,
            items: navItems.where((n) => n.enabled).toList(),
            isOnline: auth.isAuthenticated,
            footerSync: DateTime.now()
                .toString()
                .substring(11, 16),
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  title: title,
                  subtitle: subtitle,
                  tabs: tabs,
                  activeTab: activeTab,
                  onTabChanged: onTabChanged,
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF4F4F5),
                    child: ClipRRect(
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<NavItem> _buildNavItems(AuthProvider auth, dynamic user) {
    final items = <NavItem>[
      NavItem(label: 'Tiquetero', icon: Icons.confirmation_number, route: '/ticket'),
    ];

    if (!auth.isAuthenticated || user == null) return items;

    if (user.isAdmin) {
      items.addAll([
        NavItem(label: 'Dashboard', icon: Icons.dashboard, route: '/dashboard'),
        NavItem(label: 'Puestos', icon: Icons.monitor_heart, route: '/puestos'),
        NavItem(label: 'Configuración', icon: Icons.settings, route: '/settings'),
      ]);
    } else if (user.isSupervisor) {
      items.addAll([
        NavItem(label: 'Dashboard', icon: Icons.dashboard, route: '/dashboard'),
        NavItem(label: 'Puestos', icon: Icons.monitor_heart, route: '/puestos'),
      ]);
    } else if (user.isAttentionUser) {
      items.addAll([
        NavItem(label: 'Atención', icon: Icons.headset_mic, route: '/attention'),
      ]);
    }

    if (extraNavItems != null) {
      items.addAll(extraNavItems!);
    }

    return items;
  }
}
