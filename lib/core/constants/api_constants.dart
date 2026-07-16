class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:5000';
  static const String apiPrefix = '/api';
  static const String websocketUrl = 'http://localhost:5000/ticketHub';

  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;

  static const String tokenStorageKey = 'auth_token';
  static const String refreshTokenStorageKey = 'refresh_token';
  static const String userDataStorageKey = 'user_data';

  // Endpoints
  static const String loginEndpoint = '$apiPrefix/auth/login';
  static const String refreshEndpoint = '$apiPrefix/auth/refresh';
  static const String ticketsEndpoint = '$apiPrefix/tickets';
  static const String usersEndpoint = '$apiPrefix/users';
  static const String areasEndpoint = '$apiPrefix/areas';
  static const String dashboardEndpoint = '$apiPrefix/dashboard';
  static const String configurationEndpoint = '$apiPrefix/configuration';
  static const String kioskosFisicosEndpoint = '$apiPrefix/kioskos-fisicos';
  static const String detectarIpEndpoint = '$apiPrefix/kioskos-fisicos/detectar-ip';
  static const String autoRegistrarEndpoint = '$apiPrefix/kioskos-fisicos/auto-registrar';
  static String printerConfigEndpoint(int kioskoId) => '$apiPrefix/kioskos-fisicos/$kioskoId/printer-config';
  // Dashboard sub-endpoints
  static const String dashboardPuestosStatus = '$apiPrefix/dashboard/puestos-status';
  static const String dashboardUserStats = '$apiPrefix/dashboard/user-stats';
  static const String dashboardExportPdf = '$apiPrefix/dashboard/export-pdf';
  // Session endpoints (UsuariosController: api/usuarios)
  static const String sessionBase = '$apiPrefix/usuarios';
  static String openSession(int usuarioId) => '$sessionBase/$usuarioId/sesion';
  static String closeSession(int sesionOperadorId) => '$sessionBase/sesion/$sesionOperadorId/cerrar';
  // Puestos by area
  static String puestosByArea(int areaId) => '$apiPrefix/areas/$areaId/puestos';
  // Servicios by area
  static String serviciosByArea(int areaId) => '$apiPrefix/areas/$areaId/servicios';
}
