import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/kiosko_fisico.dart';

abstract class KioskoFisicoRepository {
  Future<Either<Failure, List<KioskoFisico>>> getAll();

  Future<Either<Failure, KioskoFisico>> getById(int id);

  Future<Either<Failure, KioskoFisico>> create(Map<String, dynamic> data);

  Future<Either<Failure, KioskoFisico>> update(int id, Map<String, dynamic> data);

  Future<Either<Failure, void>> delete(int id);

  Future<Either<Failure, KioskoFisico>> autoRegistrar(Map<String, dynamic> data);

  Future<Either<Failure, String>> detectarIp();

  Future<Either<Failure, Map<String, dynamic>>> getPrinterConfig(int kioskoId);

  Future<Either<Failure, void>> updatePrinterConfig(int kioskoId, Map<String, dynamic> data);
}
