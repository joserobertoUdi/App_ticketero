import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/time_sync_service.dart';
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
    // Inicializar sincronización horaria con el servidor
    final timeSync = TimeSyncService();
    unawaited(timeSync.initialize());
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
    final timeSyncService = TimeSyncService();
    return MaterialApp(
      title: 'Sistema Ticketero - Llamador',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          Provider<TimeSyncService>.value(value: timeSyncService),
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
            timeSync: timeSyncService,
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
        await sp.setSelectedKioskoId(
          k.id,
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
