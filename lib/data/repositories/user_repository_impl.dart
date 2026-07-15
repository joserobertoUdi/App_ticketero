import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/remote/user_remote_datasource.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remote;

  UserRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<User>>> getUsers() async {
    try {
      final models = await _remote.getAll();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener usuarios: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> createUser({
    required String nombreUsuario,
    required String nombreCompleto,
    required String password,
    required String rol,
    String email = '',
    int? areaId,
    List<int> areasAtencion = const [],
  }) async {
    try {
      final model = await _remote.create({
        'nombreUsuario': nombreUsuario,
        'nombreCompleto': nombreCompleto,
        'correo': email,
        'password': password,
        'rol': rol,
        'areaId': areaId,
        'areasAtencion': areasAtencion,
      });
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al crear usuario: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser({
    required int id,
    String? nombreCompleto,
    String? rol,
    int? areaId,
    List<int>? areasAtencion,
    bool? activo,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nombreCompleto != null) data['nombreCompleto'] = nombreCompleto;
      if (rol != null) data['rol'] = rol;
      if (areaId != null) data['areaId'] = areaId;
      if (areasAtencion != null) data['areasAtencion'] = areasAtencion;
      if (activo != null) data['activo'] = activo;
      final model = await _remote.update(id, data);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al actualizar usuario: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(int id) async {
    try {
      await _remote.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al eliminar usuario: $e'));
    }
  }
}
