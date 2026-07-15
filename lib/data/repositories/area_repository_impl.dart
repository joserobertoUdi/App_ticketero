import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/remote/area_remote_datasource.dart';
import '../../domain/entities/area.dart';
import '../../domain/repositories/area_repository.dart';

class AreaRepositoryImpl implements AreaRepository {
  final AreaRemoteDataSource _remote;

  AreaRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<Area>>> getAreas() async {
    try {
      final models = await _remote.getAllActive();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener areas: $e'));
    }
  }

  @override
  Future<Either<Failure, Area>> createArea({
    required String nombre,
    required String prefijo,
    required bool activo,
  }) async {
    try {
      final model = await _remote.create({
        'nombre': nombre,
        'prefijo': prefijo,
        'activo': activo,
      });
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al crear area: $e'));
    }
  }

  @override
  Future<Either<Failure, Area>> updateArea({
    required int id,
    String? nombre,
    String? prefijo,
    bool? activo,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nombre != null) data['nombre'] = nombre;
      if (prefijo != null) data['prefijo'] = prefijo;
      if (activo != null) data['activo'] = activo;
      final model = await _remote.update(id, data);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al actualizar area: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteArea(int id) async {
    try {
      await _remote.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al eliminar area: $e'));
    }
  }
}
