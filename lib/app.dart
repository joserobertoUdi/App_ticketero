import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/kiosko_selection/kiosko_selection_screen.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/puesto_selection/puesto_selection_screen.dart';
import 'presentation/screens/ticket_selection/ticket_selection_screen.dart';
import 'presentation/screens/attention/attention_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/caller/caller_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/gestion/gestion_screen.dart';
import 'presentation/screens/admin/admin_screen.dart';
import 'presentation/screens/dashboard/puesto_monitor_screen.dart';

const _publicRoutes = {'/login', '/ticket', '/kiosko-selection'};

class TicketeroApp extends StatelessWidget {
  const TicketeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Ticketero',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        final isPublic = _publicRoutes.contains(settings.name);
        if (!isPublic) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (!auth.isAuthenticated) {
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: const RouteSettings(name: '/login'),
            );
          }
        }
        return _buildRoute(settings);
      },
    );
  }

  Route<dynamic>? _buildRoute(RouteSettings settings) {
    final routes = <String, WidgetBuilder>{
      '/ticket': (_) => const TicketSelectionScreen(),
      '/kiosko-selection': (_) => const KioskoSelectionScreen(),
      '/login': (_) => const LoginScreen(),
      '/puesto-selection': (_) => const PuestoSelectionScreen(),
      '/attention': (_) => const AttentionScreen(),
      '/dashboard': (_) => const DashboardScreen(),
      '/caller': (_) => const CallerScreen(),
      '/settings': (_) => const SettingsScreen(),
      '/gestion': (_) => const GestionScreen(),
      '/admin': (_) => const AdminScreen(),
      '/puestos': (_) => const PuestoMonitorScreen(),
    };
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return null;
  }
}
