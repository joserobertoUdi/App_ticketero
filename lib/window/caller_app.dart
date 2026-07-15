import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../data/datasources/local/auth_local_datasource.dart';
import '../data/datasources/local/ticket_local_datasource.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/datasources/remote/kiosko_fisico_remote_datasource.dart';
import '../data/datasources/remote/ticket_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/kiosko_fisico_repository_impl.dart';
import '../data/repositories/ticket_repository_impl.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/kiosko_fisico_provider.dart';
import '../presentation/providers/ticket_provider.dart';
import '../presentation/providers/settings_provider.dart';
import '../presentation/screens/caller/caller_screen.dart';
import 'ticket_channel.dart';

class CallerWindowApp extends StatefulWidget {
  const CallerWindowApp({super.key});

  @override
  State<CallerWindowApp> createState() => _CallerWindowAppState();
}

class _CallerWindowAppState extends State<CallerWindowApp>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindow();
  }

  Future<void> _initWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    return MaterialApp(
      title: 'Sistema Ticketero - Llamador',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider(create: (_) => AuthProvider(
            authRepository: AuthRepositoryImpl(
              AuthRemoteDataSource(apiClient),
              AuthLocalDataSource(const FlutterSecureStorage()),
              apiClient,
            ),
          )),
          ChangeNotifierProvider(create: (_) => TicketProvider(
            ticketRepository: TicketRepositoryImpl(
              TicketRemoteDataSource(apiClient),
              TicketLocalDataSource(),
            ),
          )),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => KioskoFisicoProvider(
            KioskoFisicoRepositoryImpl(
              KioskoFisicoRemoteDataSource(apiClient),
            ),
          )),
        ],
        child: const CallerWindowScreen(),
      ),
    );
  }
}

class CallerWindowScreen extends StatefulWidget {
  const CallerWindowScreen({super.key});

  @override
  State<CallerWindowScreen> createState() => _CallerWindowScreenState();
}

class _CallerWindowScreenState extends State<CallerWindowScreen> {
  @override
  void initState() {
    super.initState();
    _listenChannel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final kioskoProvider = Provider.of<KioskoFisicoProvider>(context, listen: false);
    await sp.loadSettings();

    try {
      await kioskoProvider.loadAll();
      final activos = kioskoProvider.kioskosActivos;
      if (activos.isNotEmpty) {
        final k = activos.first;
        // Siempre usamos el kioskoMediaId del backend y las URLs directas del kiosko físico
        // No dependemos de si el media existe en la lista local de SharedPreferences
        await sp.setSelectedKioskoId(
          k.id,
          kioskoMediaId: k.kioskoMediaId,
          areaIds: k.areaIds,
          logoUrl: k.logoUrl,
          videoUrl: k.videoUrl,
          nombre: k.nombre,
        );
      }
    } catch (_) {
      // si la API falla, la config local de SharedPreferences ya cargó
    }
  }

  void _listenChannel() {
    CallerChannel.setHandler((state) {
      final tp = Provider.of<TicketProvider>(context, listen: false);
      tp.updateFromChannel(state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await windowManager.close();
        }
      },
      child: const CallerScreen(),
    );
  }
}
