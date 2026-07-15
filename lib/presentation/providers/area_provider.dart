import 'package:flutter/foundation.dart';

import '../../domain/entities/area.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/area_repository.dart';

class AreaProvider extends ChangeNotifier {
  final AreaRepository _areaRepository;

  List<Area> _areas = [];
  bool _isLoading = false;
  String? _errorMessage;

  AreaProvider({required AreaRepository areaRepository})
      : _areaRepository = areaRepository;

  List<Area> get areas => _areas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAreas() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _areaRepository.getAreas();
      result.fold(
        (failure) {
          _errorMessage = failure.message;
        },
        (areas) {
          _areas = areas;
        },
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar áreas';
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Area> get activeAreas => _areas.where((area) => area.activo).toList();

  Area? areaById(int id) {
    try {
      return _areas.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> createArea({
    required String nombre,
    required String prefijo,
    String logoUrl = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _areaRepository.createArea(
        nombre: nombre,
        prefijo: prefijo,
        activo: true,
      );
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (area) {
          _areas.add(area);
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al crear área';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateArea({
    required int id,
    required String nombre,
    required String prefijo,
    bool activo = true,
    String logoUrl = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _areaRepository.updateArea(
        id: id,
        nombre: nombre,
        prefijo: prefijo,
        activo: activo,
      );
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (area) {
          final index = _areas.indexWhere((a) => a.id == area.id);
          if (index != -1) {
            _areas[index] = area;
          }
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al actualizar área';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleAreaActive(int id) async {
    final index = _areas.indexWhere((a) => a.id == id);
    if (index == -1) return false;

    final result = await _areaRepository.updateArea(
      id: id,
      activo: !_areas[index].activo,
    );
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (area) {
        _areas[index] = area;
        notifyListeners();
        return true;
      },
    );
  }

  List<User> usersForArea(int areaId) {
    return [];
  }

  String? deleteAreaError(int areaId) {
    return null;
  }

  Future<bool> deleteArea(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _areaRepository.deleteArea(id);
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (_) {
          _areas.removeWhere((a) => a.id == id);
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al eliminar área';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
