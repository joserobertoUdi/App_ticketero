import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardStats>> getSummary({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  Future<Either<Failure, List<AreaStats>>> getByArea({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  Future<Either<Failure, List<UserStats>>> getByUser({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  });

  Future<Either<Failure, List<HourlyBreakdown>>> getHourlyBreakdown({
    required DateTime fecha,
  });
}
