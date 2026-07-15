import 'package:flutter/foundation.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class UserManagementProvider extends ChangeNotifier {
  final UserRepository _userRepository;

  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserManagementProvider({required UserRepository userRepository})
      : _userRepository = userRepository;

  List<User> get users => _users;
  List<User> get activeUsers => _users.where((u) => u.activo).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _userRepository.getUsers();
      result.fold(
        (failure) {
          _errorMessage = failure.message;
        },
        (users) {
          _users = users;
        },
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar usuarios';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String nombreUsuario,
    required String nombreCompleto,
    required String password,
    required String rol,
    String email = '',
    int? areaId,
    String? areaNombre,
    String? puesto,
    List<int> areasAtencion = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _userRepository.createUser(
        nombreUsuario: nombreUsuario,
        nombreCompleto: nombreCompleto,
        email: email,
        password: password,
        rol: rol,
        areaId: areaId,
        areasAtencion: areasAtencion,
      );
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (_) {
          loadUsers();
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al crear usuario';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(User updated, {List<int>? areasAtencion}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _userRepository.updateUser(
        id: updated.id,
        nombreCompleto: updated.nombreCompleto,
        rol: updated.rol.apiValue,
        areaId: updated.areaId,
        activo: updated.activo,
        areasAtencion: areasAtencion,
      );
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (_) {
          loadUsers();
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al actualizar usuario';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUserActive(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _users.firstWhere((u) => u.id == userId);
      final result = await _userRepository.updateUser(
        id: userId,
        activo: !user.activo,
      );
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (_) {
          loadUsers();
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al cambiar estado';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _userRepository.deleteUser(userId);
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (_) {
          loadUsers();
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al eliminar usuario';
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
