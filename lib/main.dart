import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/websocket_service.dart';
import 'core/printing/printing_provider.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/local/ticket_local_datasource.dart';
import 'data/datasources/remote/area_remote_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/dashboard_remote_datasource.dart';
import 'data/datasources/remote/ticket_remote_datasource.dart';
import 'data/datasources/remote/user_remote_datasource.dart';
import 'data/datasources/remote/kiosko_fisico_remote_datasource.dart';
import 'data/repositories/area_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'data/repositories/ticket_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/kiosko_fisico_repository_impl.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/ticket_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/area_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/user_management_provider.dart';
import 'presentation/providers/kiosko_fisico_provider.dart';
import 'presentation/providers/puesto_monitor_provider.dart';
import 'window/caller_app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  final windowController = await WindowController.fromCurrentEngine();
  final windowArgs = windowController.arguments;

  if (windowArgs == 'caller') {
    runApp(const CallerWindowApp());
    return;
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final savedX = prefs.getInt('window_x');
  final savedY = prefs.getInt('window_y');
  final savedW = prefs.getInt('window_width');
  final savedH = prefs.getInt('window_height');

  WindowOptions options = WindowOptions(
    size: Size(
      (savedW ?? 1280).toDouble(),
      (savedH ?? 720).toDouble(),
    ),
    minimumSize: const Size(800, 600),
    center: savedX == null || savedY == null,
  );

  windowManager.waitUntilReadyToShow(options, () async {
    if (savedX != null && savedY != null) {
      await windowManager.setPosition(Offset(savedX.toDouble(), savedY.toDouble()));
    }
    await windowManager.show();
    await windowManager.focus();
  });

  windowManager.setPreventClose(true);
  windowManager.addListener(WindowCloseHandler());

  final webSocketService = WebSocketService();
  webSocketService.connect();

  final apiClient = ApiClient();
  final authProvider = AuthProvider(
    authRepository: AuthRepositoryImpl(
      AuthRemoteDataSource(apiClient),
      AuthLocalDataSource(const FlutterSecureStorage()),
      apiClient,
    ),
  );
  final ticketProvider = TicketProvider(
    ticketRepository: TicketRepositoryImpl(
      TicketRemoteDataSource(apiClient),
      TicketLocalDataSource(),
    ),
  );
  final settingsProvider = SettingsProvider();

  authProvider.attachSettings(settingsProvider);

  final dashboardProvider = DashboardProvider(
    dashboardRepository: DashboardRepositoryImpl(
      DashboardRemoteDataSource(apiClient),
    ),
    apiClient: apiClient,
  );
  final areaProvider = AreaProvider(
    areaRepository: AreaRepositoryImpl(
      AreaRemoteDataSource(apiClient),
    ),
  );
  final printingProvider = PrintingProvider();
  final userManagementProvider = UserManagementProvider(
    userRepository: UserRepositoryImpl(
      UserRemoteDataSource(apiClient),
    ),
  );
  final kioskoFisicoProvider = KioskoFisicoProvider(
    KioskoFisicoRepositoryImpl(
      KioskoFisicoRemoteDataSource(apiClient),
    ),
  );
  final puestoMonitorProvider = PuestoMonitorProvider(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: ticketProvider),
        ChangeNotifierProvider.value(value: dashboardProvider),
        ChangeNotifierProvider.value(value: areaProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: printingProvider),
        ChangeNotifierProvider.value(value: userManagementProvider),
        ChangeNotifierProvider.value(value: kioskoFisicoProvider),
        ChangeNotifierProvider.value(value: puestoMonitorProvider),
        Provider<WebSocketService>.value(value: webSocketService),
      ],
      child: const TicketeroApp(),
    ),
  );
}

class WindowCloseHandler with WindowListener {
  @override
  void onWindowClose() async {
    final prefs = await SharedPreferences.getInstance();
    final pos = await windowManager.getPosition();
    final size = await windowManager.getSize();
    await prefs.setInt('window_x', pos.dx.toInt());
    await prefs.setInt('window_y', pos.dy.toInt());
    await prefs.setInt('window_width', size.width.toInt());
    await prefs.setInt('window_height', size.height.toInt());
    await windowManager.destroy();
  }
}
