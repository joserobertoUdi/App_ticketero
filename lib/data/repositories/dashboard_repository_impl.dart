import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/remote/dashboard_remote_datasource.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remote;

  DashboardRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, DashboardStats>> getSummary({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final model = await _remote.getSummary(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener resumen: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AreaStats>>> getByArea({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final result = await _remote.getByArea(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      final list = (result['areas'] as List?) ?? [];
      return Right(list.map((e) {
        final m = e as Map<String, dynamic>;
        return AreaStats(
          area: m['areaNombre'] as String? ?? '',
          total: m['total'] as int? ?? 0,
          atendidos: m['atendidos'] as int? ?? 0,
          pendientes: m['pendientes'] as int? ?? 0,
          tiempoPromedioSegundos: m['tiempoPromedio'] as int? ?? 0,
        );
      }).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener stats por area: $e'));
    }
  }

  @override
  Future<Either<Failure, List<UserStats>>> getByUser({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final result = await _remote.getByUser(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      final list = (result['usuarios'] as List?) ?? [];
      return Right(list.map((e) {
        final m = e as Map<String, dynamic>;
        return UserStats(
          nombre: m['nombreCompleto'] as String? ?? '',
          totalAtendidos: m['ticketsAtendidos'] as int? ?? 0,
          tiempoPromedioSegundos: m['tiempoPromedio'] as int? ?? 0,
        );
      }).toList());
    } catch (e) {
      return Left(
          ServerFailure(message: 'Error al obtener stats por usuario: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HourlyBreakdown>>> getHourlyBreakdown({
    required DateTime fecha,
  }) async {
    try {
      final result = await _remote.getHourlyBreakdown(fecha);
      final list = (result['horas'] as List?) ?? [];
      return Right(list.map((e) {
        final m = e as Map<String, dynamic>;
        return HourlyBreakdown(
          hora: m['hora'] as int? ?? 0,
          total: m['total'] as int? ?? 0,
        );
      }).toList());
    } catch (e) {
      return Left(
          ServerFailure(message: 'Error al obtener desglose horario: $e'));
    }
  }
}
