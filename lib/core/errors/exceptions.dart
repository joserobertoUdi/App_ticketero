class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class ConnectionException implements Exception {
  final String message;

  const ConnectionException({this.message = 'Error de conexión'});

  @override
  String toString() => 'ConnectionException: $message';
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException({required this.message, this.statusCode});

  @override
  String toString() => 'AuthException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Error de caché'});

  @override
  String toString() => 'CacheException: $message';
}
