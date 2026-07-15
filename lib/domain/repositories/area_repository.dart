import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/area.dart';

abstract class AreaRepository {
  Future<Either<Failure, List<Area>>> getAreas();

  Future<Either<Failure, Area>> createArea({
    required String nombre,
    required String prefijo,
    required bool activo,
  });

  Future<Either<Failure, Area>> updateArea({
    required int id,
    String? nombre,
    String? prefijo,
    bool? activo,
  });

  Future<Either<Failure, void>> deleteArea(int id);
}
