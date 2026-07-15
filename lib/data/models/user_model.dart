import '../../core/enums/user_role.dart';
import '../../domain/entities/user.dart';

class UserModel {
  final int id;
  final String nombreUsuario;
  final String nombreCompleto;
  final String email;
  final String rol;
  final int? areaId;
  final String? areaNombre;
  final String? puesto;
  final List<int> areasAtencion;
  final bool activo;
  final DateTime? ultimoAcceso;

  const UserModel({
    required this.id,
    required this.nombreUsuario,
    required this.nombreCompleto,
    this.email = '',
    required this.rol,
    this.areaId,
    this.areaNombre,
    this.puesto,
    this.areasAtencion = const [],
    required this.activo,
    this.ultimoAcceso,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      nombreUsuario: json['nombreUsuario'] as String? ?? '',
      nombreCompleto: json['nombreCompleto'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
      areaId: json['areaId'] as int?,
      areaNombre: json['areaNombre'] as String?,
      puesto: json['puesto'] as String?,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreUsuario': nombreUsuario,
      'nombreCompleto': nombreCompleto,
      'email': email,
      'rol': rol,
      'areaId': areaId,
      'areaNombre': areaNombre,
      'puesto': puesto,
      'areasAtencion': areasAtencion,
      'activo': activo,
      'ultimoAcceso': ultimoAcceso?.toIso8601String(),
    };
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
      puesto: puesto,
      areasAtencion: areasAtencion,
      activo: activo,
      ultimoAcceso: ultimoAcceso,
    );
  }

  static UserModel fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      nombreUsuario: entity.nombreUsuario,
      nombreCompleto: entity.nombreCompleto,
      email: entity.email,
      rol: entity.rol.apiValue,
      areaId: entity.areaId,
      areaNombre: entity.areaNombre,
      puesto: entity.puesto,
      areasAtencion: entity.areasAtencion,
      activo: entity.activo,
      ultimoAcceso: entity.ultimoAcceso,
    );
  }
}
