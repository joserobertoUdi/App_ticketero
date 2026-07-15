import '../../core/enums/user_role.dart';

class User {
  final int id;
  final String nombreUsuario;
  final String nombreCompleto;
  final String email;
  final UserRole rol;
  final int? areaId;
  final String? areaNombre;
  final String? puesto;
  final List<int> areasAtencion;
  final bool activo;
  final DateTime? ultimoAcceso;

  const User({
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

  User copyWith({
    int? id,
    String? nombreUsuario,
    String? nombreCompleto,
    String? email,
    UserRole? rol,
    int? areaId,
    String? areaNombre,
    String? puesto,
    List<int>? areasAtencion,
    bool? activo,
    DateTime? ultimoAcceso,
  }) {
    return User(
      id: id ?? this.id,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      areaId: areaId ?? this.areaId,
      areaNombre: areaNombre ?? this.areaNombre,
      puesto: puesto ?? this.puesto,
      areasAtencion: areasAtencion ?? this.areasAtencion,
      activo: activo ?? this.activo,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
    );
  }

  bool get isAdmin => rol == UserRole.administrador;
  bool get isSupervisor => rol == UserRole.supervisor;
  bool get isOperator => rol == UserRole.operador;
  bool get isCaller => rol == UserRole.llamador;
  bool get isAttentionUser => rol == UserRole.operador;
}
