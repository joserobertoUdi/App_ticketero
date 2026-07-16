import 'package:flutter/foundation.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'settings_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  String? _puestoSeleccionado;
  int? _puestoAreaId;
  int? _puestoId;
  int? _sesionOperadorId;
  DateTime? _fechaIngreso;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  void attachSettings(SettingsProvider settings) {
  }

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;
  String? get errorMessage => _errorMessage;
  String? get puestoSeleccionado => _puestoSeleccionado;
  int? get puestoId => _puestoId;
  int? get sesionOperadorId => _sesionOperadorId;
  DateTime? get fechaIngreso => _fechaIngreso;

  void setPuestoSeleccionado(String puesto, {int? areaId, int? puestoId}) {
    _puestoSeleccionado = puesto;
    _puestoAreaId = areaId;
    _puestoId = puestoId;
  }

  Future<String?> openSession(int usuarioId, int puestoId) async {
    final result = await _authRepository.openSession(usuarioId, puestoId);
    return result.fold(
      (failure) => failure.message,
      (sesionId) {
        _sesionOperadorId = sesionId;
        _fechaIngreso = DateTime.now();
        return null;
      },
    );
  }

  Future<String?> closeSession() async {
    if (_sesionOperadorId == null) return null;
    final result = await _authRepository.closeSession(_sesionOperadorId!);
    return result.fold(
      (failure) => failure.message,
      (_) {
        _sesionOperadorId = null;
        _fechaIngreso = null;
        return null;
      },
    );
  }

  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isSupervisor => _user?.isSupervisor ?? false;
  bool get isAttentionUser => _user?.isAttentionUser ?? false;
  bool get isCaller => _user?.isCaller ?? false;

  Future<bool> login(String correo, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(correo, password);
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (authResult) {
          _user = authResult.user;
          _token = authResult.token;
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error de conexión';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_sesionOperadorId != null) {
      await closeSession();
    }
    _user = null;
    _token = null;
    _errorMessage = null;
    _puestoSeleccionado = null;
    _puestoAreaId = null;
    _puestoId = null;
    _sesionOperadorId = null;
    _fechaIngreso = null;
    notifyListeners();

    await _authRepository.logout();
  }
}
