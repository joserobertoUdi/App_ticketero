import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../data/datasources/remote/kiosko_fisico_remote_datasource.dart';
import '../../data/models/kiosko_fisico_model.dart';
import '../../domain/entities/kiosko_fisico.dart';
import '../../domain/repositories/kiosko_fisico_repository.dart';

class KioskoFisicoRepositoryImpl implements KioskoFisicoRepository {
  final KioskoFisicoRemoteDataSource _remote;

  KioskoFisicoRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<KioskoFisico>>> getAll() async {
    try {
      final models = await _remote.getAll();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener kioskos físicos: $e'));
    }
  }

  @override
  Future<Either<Failure, KioskoFisico>> getById(int id) async {
    try {
      final model = await _remote.getById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener kiosko físico: $e'));
    }
  }

  Map<String, List<String>>? _parseValidationErrors(DioException e) {
    if (e.response?.statusCode == 400 && e.response?.data is Map) {
      final errors = (e.response!.data as Map)['errors'];
      if (errors is Map) {
        return errors.map((k, v) => MapEntry(k.toString(), (v as List).cast<String>()));
      }
    }
    return null;
  }

  @override
  Future<Either<Failure, KioskoFisico>> create(Map<String, dynamic> data) async {
    try {
      final model = await _remote.create(data);
      return Right(model.toEntity());
    } catch (e) {
      if (e is DioException) {
        final errors = _parseValidationErrors(e);
        if (errors != null) {
          return Left(ValidationFailure(
            message: 'Error de validación',
            errors: errors,
          ));
        }
      }
      return Left(ServerFailure(message: 'Error al crear kiosko físico: $e'));
    }
  }

  @override
  Future<Either<Failure, KioskoFisico>> update(int id, Map<String, dynamic> data) async {
    try {
      final model = await _remote.update(id, data);
      return Right(model.toEntity());
    } catch (e) {
      if (e is DioException) {
        final errors = _parseValidationErrors(e);
        if (errors != null) {
          return Left(ValidationFailure(
            message: 'Error de validación',
            errors: errors,
          ));
        }
      }
      return Left(ServerFailure(message: 'Error al actualizar kiosko físico: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(int id) async {
    try {
      await _remote.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al eliminar kiosko físico: $e'));
    }
  }

  @override
  Future<Either<Failure, KioskoFisico>> autoRegistrar(Map<String, dynamic> data) async {
    try {
      final model = await _remote.autoRegistrar(data);
      return Right(KioskoFisicoModel.fromJson(model).toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al auto-registrar kiosko: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> detectarIp() async {
    try {
      final result = await _remote.detectarIp();
      return Right(result['ip'] as String? ?? '');
    } catch (e) {
      return Left(ServerFailure(message: 'Error al detectar IP: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPrinterConfig(int kioskoId) async {
    try {
      final data = await _remote.getPrinterConfig(kioskoId);
      return Right(data);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener configuración de impresora: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePrinterConfig(int kioskoId, Map<String, dynamic> data) async {
    try {
      await _remote.updatePrinterConfig(kioskoId, data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al actualizar configuración de impresora: $e'));
    }
  }
}
