import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/kiosko_media.dart';
import '../../domain/entities/puesto_info.dart';
import '../../domain/entities/service_type.dart';

class SettingsProvider extends ChangeNotifier {
  int _tiempoEstimadoMinutos = 5;
  int _maxTicketsPorDia = 500;
  String _serverUrl = 'http://localhost:5000';
  bool _isLoading = false;
  String? _errorMessage;

  List<KioskoMedia> _kioskoLocations = [];
  int? _selectedKioskoId;
  int? _selectedKioskoMediaId;
  Set<int> _selectedKioskoAreaIds = {};
  String? _selectedKioskoLogoUrl;
  String? _selectedKioskoVideoUrl;
  String _selectedKioskoNombre = '';
  final Map<int, List<PuestoInfo>> _puestosPorArea = {};
  final Map<int, List<ServiceType>> _serviceTypesPorArea = {};

  static const _keyKioskoMedias = 'kiosko_locations';
  static const _keySelectedKiosko = 'selected_kiosko_id';
  static const _keySelectedKioskoMedia = 'selected_kiosko_media_id';
  static const _keySelectedKioskoAreas = 'selected_kiosko_area_ids';
  static const _keySelectedKioskoLogo = 'selected_kiosko_logo_url';
  static const _keySelectedKioskoVideo = 'selected_kiosko_video_url';
  static const _keySelectedKioskoNombre = 'selected_kiosko_nombre';
  static const _keyPuestosPorArea = 'puestos_por_area';
  static const _keyServerUrl = 'server_url';
  static const _keyTimeEstimate = 'tiempo_estimado';
  static const _keyMaxTickets = 'max_tickets';
  static const _keyServiceTypesPorArea = 'service_types_por_area';

  // Gap 16: Timestamps de caché para invalidación periódica
  static const Duration _cacheTtl = Duration(minutes: 30);
  DateTime? _puestosCachedAt;
  DateTime? _serviceTypesCachedAt;

  int get tiempoEstimadoMinutos => _tiempoEstimadoMinutos;
  int get maxTicketsPorDia => _maxTicketsPorDia;
  String get serverUrl => _serverUrl;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<KioskoMedia> get kioskoLocations => List.unmodifiable(_kioskoLocations);
  int? get selectedKioskoId => _selectedKioskoId;
  bool get hasKioskoSelected => _selectedKioskoId != null;

  KioskoMedia? get selectedKiosko {
    if (_selectedKioskoId == null) return null;
    final mediaId = _selectedKioskoMediaId ?? _selectedKioskoId;
    try {
      return _kioskoLocations.firstWhere((k) => k.id == mediaId);
    } catch (_) {
      // Si el KioskoMedia local no existe, siempre construimos uno con los valores
      // directos del kiosko físico (logoUrl/videoUrl vienen del backend)
      return KioskoMedia(
        id: _selectedKioskoMediaId ?? _selectedKioskoId!,
        nombre: _selectedKioskoNombre,
        areaIds: _selectedKioskoAreaIds,
        logoUrl: _selectedKioskoLogoUrl ?? '',
        videoUrl: _selectedKioskoVideoUrl ?? '',
      );
    }
  }

  Set<int> get kioskoAreaIds =>
      _selectedKioskoAreaIds.isNotEmpty ? Set.unmodifiable(_selectedKioskoAreaIds) : {};

  List<PuestoInfo> puestosForArea(int areaId) =>
      List.unmodifiable(_puestosPorArea[areaId] ?? []);

  List<ServiceType> serviceTypesForArea(int areaId) =>
      List.unmodifiable(_serviceTypesPorArea[areaId] ?? []);

  Future<void> setPuestosForArea(int areaId, List<PuestoInfo> puestos) async {
    _puestosPorArea[areaId] = List.from(puestos);
    _puestosCachedAt = DateTime.now(); // Gap 16: registrar tiempo de caché
    await _persistPuestos();
    notifyListeners();
  }

  Future<void> occupyPuesto(int areaId, int puestoId, int userId) async {
    final puestos = _puestosPorArea[areaId];
    if (puestos == null) return;
    final idx = puestos.indexWhere((p) => p.id == puestoId);
    if (idx == -1) return;
    puestos[idx] = puestos[idx].copyWith(occupiedByUserId: userId);
    await _persistPuestos();
    notifyListeners();
  }

  Future<void> freePuesto(int areaId, int puestoId) async {
    final puestos = _puestosPorArea[areaId];
    if (puestos == null) return;
    final idx = puestos.indexWhere((p) => p.id == puestoId);
    if (idx == -1) return;
    puestos[idx] = puestos[idx].copyWith(clearOccupied: true);
    await _persistPuestos();
    notifyListeners();
  }

  Future<void> removePuestosForArea(int areaId) async {
    _puestosPorArea.remove(areaId);
    await _persistPuestos();
    notifyListeners();
  }

  Future<void> setServiceTypesForArea(int areaId, List<ServiceType> types) async {
    _serviceTypesPorArea[areaId] = List.from(types);
    _serviceTypesCachedAt = DateTime.now(); // Gap 16: registrar tiempo de caché
    await _persistServiceTypes();
    notifyListeners();
  }

  /// Gap 16: ¿El caché de puestos está obsoleto (>30 min)?
  bool get isPuestosStale =>
      _puestosCachedAt == null ||
      DateTime.now().difference(_puestosCachedAt!) > _cacheTtl;

  /// Gap 16: ¿El caché de servicios está obsoleto (>30 min)?
  bool get isServiceTypesStale =>
      _serviceTypesCachedAt == null ||
      DateTime.now().difference(_serviceTypesCachedAt!) > _cacheTtl;

  /// Gap 16: Invalidar caché de puestos bajo demanda (p.ej. desde panel admin)
  Future<void> invalidatePuestosCache() async {
    _puestosPorArea.clear();
    _puestosCachedAt = null;
    await _persistPuestos();
    notifyListeners();
  }

  /// Gap 16: Invalidar caché de servicios bajo demanda
  Future<void> invalidateServiceTypesCache() async {
    _serviceTypesPorArea.clear();
    _serviceTypesCachedAt = null;
    await _persistServiceTypes();
    notifyListeners();
  }

  Future<void> removeServiceTypesForArea(int areaId) async {
    _serviceTypesPorArea.remove(areaId);
    await _persistServiceTypes();
    notifyListeners();
  }

  Future<void> _persistPuestos() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final entry in _puestosPorArea.entries) {
      map[entry.key.toString()] = entry.value.map((p) => p.toJson()).toList();
    }
    await prefs.setString(_keyPuestosPorArea, jsonEncode(map));
  }

  Future<void> _persistServiceTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final entry in _serviceTypesPorArea.entries) {
      map[entry.key.toString()] = entry.value.map((s) => s.toJson()).toList();
    }
    await prefs.setString(_keyServiceTypesPorArea, jsonEncode(map));
  }

  String? get selectedKioskoLogoUrl => _selectedKioskoLogoUrl;
  String? get selectedKioskoVideoUrl => _selectedKioskoVideoUrl;
  String get selectedKioskoNombre => _selectedKioskoNombre;

  Future<void> setSelectedKioskoId(int? id, {int? kioskoMediaId, List<int>? areaIds, String? logoUrl, String? videoUrl, String? nombre}) async {
    _selectedKioskoId = id;
    _selectedKioskoMediaId = kioskoMediaId;
    _selectedKioskoAreaIds = areaIds?.toSet() ?? {};
    // Siempre actualizamos, aunque sea null, para no mantener valores stale de una sesión anterior
    _selectedKioskoLogoUrl = logoUrl?.isNotEmpty == true ? logoUrl : null;
    _selectedKioskoVideoUrl = videoUrl?.isNotEmpty == true ? videoUrl : null;
    if (nombre != null) _selectedKioskoNombre = nombre;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_keySelectedKiosko, id.toString());
      if (kioskoMediaId != null) {
        await prefs.setString(_keySelectedKioskoMedia, kioskoMediaId.toString());
      } else {
        await prefs.remove(_keySelectedKioskoMedia);
      }
      await prefs.setString(_keySelectedKioskoAreas, (areaIds ?? []).join(','));
      // Siempre persistir logo/video: si hay valor lo guardamos, si no lo borramos
      if (logoUrl != null && logoUrl.isNotEmpty) {
        await prefs.setString(_keySelectedKioskoLogo, logoUrl);
      } else {
        await prefs.remove(_keySelectedKioskoLogo);
      }
      if (videoUrl != null && videoUrl.isNotEmpty) {
        await prefs.setString(_keySelectedKioskoVideo, videoUrl);
      } else {
        await prefs.remove(_keySelectedKioskoVideo);
      }
      if (nombre != null) await prefs.setString(_keySelectedKioskoNombre, nombre);
    } else {
      await prefs.remove(_keySelectedKiosko);
      await prefs.remove(_keySelectedKioskoMedia);
      await prefs.remove(_keySelectedKioskoAreas);
      await prefs.remove(_keySelectedKioskoLogo);
      await prefs.remove(_keySelectedKioskoVideo);
      await prefs.remove(_keySelectedKioskoNombre);
    }
    notifyListeners();
  }

  Future<void> addKioskoMedia(KioskoMedia location) async {
    _kioskoLocations.add(location);
    await _persistKioskoMedias();
    notifyListeners();
  }

  Future<void> updateKioskoMedia(KioskoMedia location) async {
    final idx = _kioskoLocations.indexWhere((k) => k.id == location.id);
    if (idx == -1) return;
    _kioskoLocations[idx] = location;
    await _persistKioskoMedias();
    notifyListeners();
  }

  Future<void> deleteKioskoMedia(int id) async {
    _kioskoLocations.removeWhere((k) => k.id == id);
    if (_selectedKioskoId == id) {
      _selectedKioskoId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySelectedKiosko);
    }
    await _persistKioskoMedias();
    notifyListeners();
  }

  Future<void> updateKioskoMultimedia(int kioskoId, {String? logoUrl, String? videoUrl, bool clearLogo = false, bool clearVideo = false}) async {
    final idx = _kioskoLocations.indexWhere((k) => k.id == kioskoId);
    if (idx == -1) return;
    _kioskoLocations[idx] = _kioskoLocations[idx].copyWith(
      logoUrl: clearLogo ? '' : logoUrl,
      videoUrl: clearVideo ? '' : videoUrl,
      clearLogo: clearLogo,
      clearVideo: clearVideo,
    );
    await _persistKioskoMedias();
    notifyListeners();
  }

  Future<void> _persistKioskoMedias() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _kioskoLocations.map((k) => k.toJson()).toList();
    await prefs.setString(_keyKioskoMedias, jsonEncode(jsonList));
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsStr = prefs.getString(_keyKioskoMedias);
      if (locationsStr != null && locationsStr.isNotEmpty) {
        final list = jsonDecode(locationsStr) as List;
        _kioskoLocations = list.map((e) => KioskoMedia.fromJson(e as Map<String, dynamic>)).toList();
      }

      final selectedStr = prefs.getString(_keySelectedKiosko);
      if (selectedStr != null && selectedStr.isNotEmpty) {
        _selectedKioskoId = int.tryParse(selectedStr);
      }

      final mediaIdStr = prefs.getString(_keySelectedKioskoMedia);
      if (mediaIdStr != null && mediaIdStr.isNotEmpty) {
        _selectedKioskoMediaId = int.tryParse(mediaIdStr);
      }

      final areasStr = prefs.getString(_keySelectedKioskoAreas);
      if (areasStr != null && areasStr.isNotEmpty) {
        _selectedKioskoAreaIds = areasStr.split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toSet();
      }
      _selectedKioskoLogoUrl = prefs.getString(_keySelectedKioskoLogo);
      _selectedKioskoVideoUrl = prefs.getString(_keySelectedKioskoVideo);
      _selectedKioskoNombre = prefs.getString(_keySelectedKioskoNombre) ?? '';

      final puestosStr = prefs.getString(_keyPuestosPorArea);
      if (puestosStr != null && puestosStr.isNotEmpty) {
        final map = jsonDecode(puestosStr) as Map<String, dynamic>;
        _puestosPorArea.clear();
        for (final entry in map.entries) {
          final areaId = int.tryParse(entry.key);
          if (areaId == null) continue;
          final list = entry.value as List;
          _puestosPorArea[areaId] =
              list.map((e) => PuestoInfo.fromJson(e as Map<String, dynamic>)).toList();
        }
      }

      final servicesStr = prefs.getString(_keyServiceTypesPorArea);
      if (servicesStr != null && servicesStr.isNotEmpty) {
        final map = jsonDecode(servicesStr) as Map<String, dynamic>;
        _serviceTypesPorArea.clear();
        for (final entry in map.entries) {
          final areaId = int.tryParse(entry.key);
          if (areaId == null) continue;
          final list = entry.value as List;
          _serviceTypesPorArea[areaId] =
              list.map((e) => ServiceType.fromJson(e as Map<String, dynamic>)).toList();
        }
      }

      _tiempoEstimadoMinutos = prefs.getInt(_keyTimeEstimate) ?? 5;
      _maxTicketsPorDia = prefs.getInt(_keyMaxTickets) ?? 500;
      _serverUrl = prefs.getString(_keyServerUrl) ?? 'http://localhost:5000';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar configuración';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTimeEstimate(int minutes) async {
    _tiempoEstimadoMinutos = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimeEstimate, minutes);
    notifyListeners();
  }

  Future<void> updateMaxTickets(int max) async {
    _maxTicketsPorDia = max;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxTickets, max);
    notifyListeners();
  }

  Future<void> updateServerUrl(String url) async {
    _serverUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
    notifyListeners();
  }
}
