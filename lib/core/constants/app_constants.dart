class AppConstants {
  AppConstants._();

  static const String appName = 'Sistema Ticketero';
  static const String version = '1.0.0';

  static const int estimatedWaitMinutes = 5;
  static const int maxTicketsPerDay = 500;
  static const int autoReturnSeconds = 10;

  static const int dashboardCacheSeconds = 30;

  static const String dateFormatDisplay = 'dd/MM/yyyy';
  static const String timeFormatDisplay = 'HH:mm:ss';
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy HH:mm:ss';
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String dateTimeFormatApi = 'yyyy-MM-ddTHH:mm:ss';

  static const int maxLoginAttempts = 5;
  static const int loginLockoutMinutes = 15;
}
