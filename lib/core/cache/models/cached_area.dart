class CachedArea {
  final int id;
  String nombre;
  bool activo;
  final String prefijo;
  String logoUrl;

  CachedArea({
    required this.id,
    required this.nombre,
    this.activo = true,
    this.prefijo = '',
    this.logoUrl = '',
  });
}
