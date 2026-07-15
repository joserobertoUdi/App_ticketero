import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:sistema_ticketero/core/errors/failures.dart';
import '../../domain/entities/kiosko_fisico.dart';
import '../../domain/repositories/kiosko_fisico_repository.dart';

class KioskoFisicoProvider extends ChangeNotifier {
  final KioskoFisicoRepository _repository;

  KioskoFisicoProvider(this._repository);

  List<KioskoFisico> _kioskos = [];
  KioskoFisico? _selected;
  bool _isLoading = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = {};

  List<KioskoFisico> get kioskos => List.unmodifiable(_kioskos);
  KioskoFisico? get selected => _selected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, List<String>> get fieldErrors => _fieldErrors;
  List<KioskoFisico> get kioskosActivos => _kioskos.where((k) => k.activo).toList();

  void clearErrors() {
    _error = null;
    _fieldErrors = {};
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    _fieldErrors = {};
    notifyListeners();

    final result = await _repository.getAll();
    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (kioskos) {
        _kioskos = kioskos;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<Either<Failure, KioskoFisico>> create(Map<String, dynamic> data) async {
    _error = null;
    _fieldErrors = {};
    notifyListeners();

    final result = await _repository.create(data);
    result.fold(
      (failure) {
        _error = failure.message;
        if (failure is ValidationFailure) {
          final errors = failure.errors;
          if (errors != null) {
            _fieldErrors = errors;
          }
        }
        notifyListeners();
      },
      (kiosko) {
        _kioskos.add(kiosko);
        notifyListeners();
      },
    );
    return result;
  }

  Future<Either<Failure, KioskoFisico>> update(int id, Map<String, dynamic> data) async {
    _error = null;
    _fieldErrors = {};
    notifyListeners();

    final result = await _repository.update(id, data);
    result.fold(
      (failure) {
        _error = failure.message;
        if (failure is ValidationFailure) {
          final errors = failure.errors;
          if (errors != null) {
            _fieldErrors = errors;
          }
        }
        notifyListeners();
      },
      (kiosko) {
        final idx = _kioskos.indexWhere((k) => k.id == id);
        if (idx != -1) _kioskos[idx] = kiosko;
        if (_selected?.id == id) _selected = kiosko;
        notifyListeners();
      },
    );
    return result;
  }

  Future<bool> delete(int id) async {
    final result = await _repository.delete(id);
    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _kioskos.removeWhere((k) => k.id == id);
        if (_selected?.id == id) _selected = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<KioskoFisico?> autoRegistrar(Map<String, dynamic> data) async {
    final result = await _repository.autoRegistrar(data);
    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return null;
      },
      (kiosko) {
        final idx = _kioskos.indexWhere((k) => k.id == kiosko.id);
        if (idx != -1) {
          _kioskos[idx] = kiosko;
        } else {
          _kioskos.add(kiosko);
        }
        _selected = kiosko;
        notifyListeners();
        return kiosko;
      },
    );
  }

  Future<String?> detectarIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getPrinterConfig(int kioskoId) async {
    final result = await _repository.getPrinterConfig(kioskoId);
    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return null;
      },
      (data) => data,
    );
  }

  Future<bool> updatePrinterConfig(int kioskoId, Map<String, dynamic> data) async {
    final result = await _repository.updatePrinterConfig(kioskoId, data);
    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (_) => true,
    );
  }

  void select(int? id) {
    if (id == null) {
      _selected = null;
    } else {
      _selected = _kioskos.where((k) => k.id == id).firstOrNull;
    }
    notifyListeners();
  }
}
