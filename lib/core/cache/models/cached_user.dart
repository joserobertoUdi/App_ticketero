class CachedUser {
  final int id;
  String nombreUsuario;
  String nombreCompleto;
  String email;
  String password;
  String rol;
  int? areaId;
  String? areaNombre;
  String? puesto;
  List<int> areasAtencion;
  bool activo;

  CachedUser({
    required this.id,
    required this.nombreUsuario,
    required this.nombreCompleto,
    this.email = '',
    required this.password,
    required this.rol,
    this.areaId,
    this.areaNombre,
    this.puesto,
    this.areasAtencion = const [],
    this.activo = true,
  });
}
