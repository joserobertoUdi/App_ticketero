import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<Either<Failure, List<User>>> getUsers();

  Future<Either<Failure, User>> createUser({
    required String nombreUsuario,
    required String nombreCompleto,
    required String email,
    required String password,
    required String rol,
    int? areaId,
    List<int> areasAtencion = const [],
  });

  Future<Either<Failure, User>> updateUser({
    required int id,
    String? nombreCompleto,
    String? rol,
    int? areaId,
    List<int>? areasAtencion,
    bool? activo,
  });

  Future<Either<Failure, void>> deleteUser(int id);
}
