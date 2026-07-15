class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  String toString() => 'Failure(message: $message, statusCode: $statusCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => message.hashCode ^ statusCode.hashCode;
}

class ServerFailure extends Failure {
  const ServerFailure({String message = 'Error del servidor', int? statusCode})
      : super(message: message, statusCode: statusCode);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure({String message = 'Error de conexión'})
      : super(message: message);
}

class AuthFailure extends Failure {
  const AuthFailure({String message = 'Error de autenticación', int? statusCode})
      : super(message: message, statusCode: statusCode);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure({String message = 'Error de validación', this.errors})
      : super(message: message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({String message = 'Recurso no encontrado'})
      : super(message: message);
}

class CacheFailure extends Failure {
  const CacheFailure({String message = 'Error de caché'})
      : super(message: message);
}
