import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/time_sync_service.dart';
import '../../data/datasources/remote/dashboard_remote_datasource.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _dashboardRepository;
  final TimeSyncService _timeSync;
  late final DashboardRemoteDataSource _remote;

  DashboardStats? _summary;
  List<AreaStats> _areaStats = [];
  List<UserStats> _userStats = [];
  List<HourlyBreakdown> _hourlyBreakdown = [];
  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;
  DashboardPeriod _selectedPeriod = DashboardPeriod.hoy;

  int? _lastLoadedAt;
  static final Duration _cacheDuration = Duration(seconds: AppConstants.dashboardCacheSeconds);

  DashboardProvider({
    required this._dashboardRepository,
    ApiClient? apiClient,
    TimeSyncService? timeSync,
  }) : _timeSync = timeSync ?? TimeSyncService(),
       _remote = DashboardRemoteDataSource(
           apiClient ?? ApiClient());

  List<String> _filterAreaNombres = [];

  void setFilterAreas(List<String> areaNombres) {
    _filterAreaNombres = areaNombres;
  }

  DashboardStats? get summary => _summary;
  List<AreaStats> get areaStats => _filterAreaNombres.isEmpty
      ? _areaStats
      : _areaStats.where((s) => _filterAreaNombres.contains(s.area)).toList();
  List<UserStats> get userStats => _userStats;
  List<HourlyBreakdown> get hourlyBreakdown => _hourlyBreakdown;
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;
  DashboardPeriod get selectedPeriod => _selectedPeriod;

  bool get _isCacheStale {
    if (_lastLoadedAt == null) return true;
    return _timeSync.serverNow().millisecondsSinceEpoch - _lastLoadedAt! > _cacheDuration.inMilliseconds;
  }

  void setPeriod(DashboardPeriod period) {
    _selectedPeriod = period;
    _lastLoadedAt = null;
    notifyListeners();
    loadDashboard();
  }

  Future<String?> exportPdf() async {
    _isExporting = true;
    notifyListeners();

    try {
      final now = _timeSync.serverNow();
      DateTime fechaInicio, fechaFin;

      switch (_selectedPeriod) {
        case DashboardPeriod.hoy:
          fechaInicio = DateTime.utc(now.year, now.month, now.day);
          fechaFin = fechaInicio.add(const Duration(days: 1));
        case DashboardPeriod.semana:
          fechaInicio = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          fechaFin = fechaInicio.add(const Duration(days: 7));
        case DashboardPeriod.mes:
          fechaInicio = DateTime.utc(now.year, now.month, 1);
          fechaFin = DateTime.utc(now.year, now.month + 1, 1);
      }

      final bytes = await _remote.getExportPdf(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      Directory docsDir;
      try {
        docsDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        final temp = await getTemporaryDirectory();
        docsDir = temp;
      }
      final fileName = 'reporte_${fechaInicio.toIso8601String().split('T').first}_${fechaFin.toIso8601String().split('T').first}.pdf';
      final filePath = '${docsDir.path}${Platform.isWindows ? '\\' : '/'}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _isExporting = false;
      notifyListeners();
      return filePath;
    } catch (e) {
      _isExporting = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadDashboard() async {
    if (!_isCacheStale && _summary != null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final now = _timeSync.serverNow();
      DateTime fechaInicio, fechaFin;

      switch (_selectedPeriod) {
        case DashboardPeriod.hoy:
          fechaInicio = DateTime.utc(now.year, now.month, now.day);
          fechaFin = fechaInicio.add(const Duration(days: 1));
        case DashboardPeriod.semana:
          fechaInicio = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          fechaFin = fechaInicio.add(const Duration(days: 7));
        case DashboardPeriod.mes:
          fechaInicio = DateTime.utc(now.year, now.month, 1);
          fechaFin = DateTime.utc(now.year, now.month + 1, 1);
      }

      final summaryF = _dashboardRepository.getSummary(fechaInicio: fechaInicio, fechaFin: fechaFin);
      final areaF = _dashboardRepository.getByArea(fechaInicio: fechaInicio, fechaFin: fechaFin);
      final userF = _dashboardRepository.getByUser(fechaInicio: fechaInicio, fechaFin: fechaFin);
      final hourlyF = _dashboardRepository.getHourlyBreakdown(fecha: now);

      final summaryResult = await summaryF;
      summaryResult.fold(
        (failure) => _errorMessage = failure.message,
        (stats) => _summary = stats,
      );

      final areaResult = await areaF;
      areaResult.fold(
        (failure) => _errorMessage = failure.message,
        (stats) => _areaStats = stats,
      );

      final userResult = await userF;
      userResult.fold(
        (failure) => _errorMessage = failure.message,
        (stats) => _userStats = stats,
      );

      final hourlyResult = await hourlyF;
      hourlyResult.fold(
        (failure) => _errorMessage = failure.message,
        (breakdown) => _hourlyBreakdown = breakdown,
      );

      _lastLoadedAt = _timeSync.serverNow().millisecondsSinceEpoch;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar dashboard';
      _isLoading = false;
      notifyListeners();
    }
  }
}

enum DashboardPeriod { hoy, semana, mes }
