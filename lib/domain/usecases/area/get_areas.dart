import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/area.dart';
import '../../repositories/area_repository.dart';

class GetAreas {
  final AreaRepository repository;

  GetAreas(this.repository);

  Future<Either<Failure, List<Area>>> call() {
    return repository.getAreas();
  }
}
