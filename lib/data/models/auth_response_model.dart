import '../../core/enums/user_role.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthResponseModel {
  final String token;
  final String refreshToken;
  final UserResponseModel usuario;
  final String expiraEn;

  const AuthResponseModel({
    required this.token,
    required this.refreshToken,
    required this.usuario,
    required this.expiraEn,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      usuario: json['usuario'] != null
          ? UserResponseModel.fromJson(json['usuario'] as Map<String, dynamic>)
          : UserResponseModel(id: 0, nombreUsuario: '', nombreCompleto: '', rol: '', activo: false),
      expiraEn: json['expiraEn'] as String? ?? '',
    );
  }

  AuthResult toAuthResult() {
    return AuthResult(
      user: usuario.toEntity(),
      token: token,
      refreshToken: refreshToken,
      expiresAt: DateTime.parse(expiraEn),
    );
  }
}

class UserResponseModel {
  final int id;
  final String nombreUsuario;
  final String nombreCompleto;
  final String email;
  final String rol;
  final int? areaId;
  final String? areaNombre;
  final List<int> areasAtencion;
  final bool activo;
  final DateTime? ultimoAcceso;

  const UserResponseModel({
    required this.id,
    required this.nombreUsuario,
    required this.nombreCompleto,
    this.email = '',
    required this.rol,
    this.areaId,
    this.areaNombre,
    this.areasAtencion = const [],
    required this.activo,
    this.ultimoAcceso,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      id: json['id'] as int? ?? 0,
      nombreUsuario: json['nombreUsuario'] as String? ?? '',
      nombreCompleto: json['nombreCompleto'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
      areaId: json['areaId'] as int?,
      areaNombre: json['areaNombre'] as String?,
      areasAtencion: (json['areasAtencion'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      activo: json['activo'] as bool? ?? true,
      ultimoAcceso: json['ultimoAcceso'] != null
          ? DateTime.parse(json['ultimoAcceso'] as String)
          : null,
    );
  }

  User toEntity() {
    return User(
      id: id,
      nombreUsuario: nombreUsuario,
      nombreCompleto: nombreCompleto,
      email: email,
      rol: UserRole.fromApiValue(rol),
      areaId: areaId,
      areaNombre: areaNombre,
      areasAtencion: areasAtencion,
      activo: activo,
      ultimoAcceso: ultimoAcceso,
    );
  }
}
