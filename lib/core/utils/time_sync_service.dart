import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class TimeSyncService {
  static final TimeSyncService _instance = TimeSyncService._internal();
  factory TimeSyncService() => _instance;
  TimeSyncService._internal();

  Duration _offset = Duration.zero;
  bool _synced = false;
  DateTime? _lastSyncAt;
  Timer? _syncTimer;

  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _maxDrift = Duration(seconds: 5);

  bool get isSynced => _synced;

  DateTime get lastSyncAt => _lastSyncAt ?? DateTime(2000);

  Duration get offset => _offset;

  Duration get roundTripDuration => _lastRoundTrip;
  Duration _lastRoundTrip = Duration.zero;

  Future<void> initialize({bool startPeriodicSync = true}) async {
    await _sync();
    if (startPeriodicSync) {
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(_syncInterval, (_) => _sync());
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _sync() async {
    try {
      final requestStart = DateTime.now().toUtc();

      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      final response = await dio.get('/api/time');
      final requestEnd = DateTime.now().toUtc();

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final serverTimeStr = data['serverTime'] as String;
        final serverTimeUtc = DateTime.parse(serverTimeStr);

        _lastRoundTrip = requestEnd.difference(requestStart);
        final estimatedLatency = _lastRoundTrip ~/ 2;
        final estimatedServerNow = serverTimeUtc.add(estimatedLatency);

        _offset = estimatedServerNow.difference(requestEnd);
        _synced = true;
        _lastSyncAt = requestEnd;
      }
    } catch (_) {
      if (!_synced) {
        _offset = Duration.zero;
      }
    }
  }

  DateTime serverNow() {
    return DateTime.now().toUtc().add(_offset);
  }

  DateTime localFromServer(DateTime serverUtc) {
    return serverUtc.subtract(_offset).toLocal();
  }

  DateTime serverFromLocal(DateTime local) {
    return local.toUtc().add(_offset);
  }

  String formatServerTime() {
    final now = serverNow();
    final local = now.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String formatServerDate() {
    final now = serverNow();
    final local = now.toLocal();
    final days = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${days[local.weekday - 1]} ${local.day} de ${months[local.month - 1]} de ${local.year}';
  }

  bool get isDriftAcceptable {
    return _offset.abs() < _maxDrift;
  }
}
