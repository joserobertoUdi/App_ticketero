import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user.dart';

class AuthResult {
  final User user;
  final String token;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthResult({
    required this.user,
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
  });
}

abstract class AuthRepository {
  Future<Either<Failure, AuthResult>> login(
      String correo, String password);

  Future<Either<Failure, AuthResult>> refreshToken(String refreshToken);

  Future<void> logout();

  Future<Either<Failure, bool>> isAuthenticated();
}
