import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/area_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/user_management_panel.dart';
import 'widgets/area_management_panel.dart';
import 'widgets/system_config_panel.dart';
import 'widgets/printer_config_panel.dart';
import 'widgets/kiosko_media_panel.dart';
import 'widgets/kioskos_administracion_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final _panels = const [
    _PanelItem('Usuarios', Icons.people, UserManagementPanel()),
    _PanelItem('Áreas', Icons.business, AreaManagementPanel()),
    _PanelItem('Kiosko Media', Icons.tv, KioskoMediaPanel()),
    _PanelItem('Kioskos Admin', Icons.document_scanner, KioskosAdministracionPanel()),
    _PanelItem('Impresora', Icons.print, PrinterConfigPanel()),
    _PanelItem('Sistema', Icons.settings, SystemConfigPanel()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).loadSettings();
      Provider.of<AreaProvider>(context, listen: false).loadAreas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Dashboard',
            onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: _panels
                .map((p) => NavigationRailDestination(
                      icon: Icon(p.icon),
                      label: Text(p.title),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _panels[_selectedIndex].widget,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelItem {
  final String title;
  final IconData icon;
  final Widget widget;

  const _PanelItem(this.title, this.icon, this.widget);
}
