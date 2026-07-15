class Area {
  final int id;
  final String nombre;
  final String prefijo;
  final String logoUrl;
  final bool activo;

  const Area({
    required this.id,
    required this.nombre,
    required this.prefijo,
    this.logoUrl = '',
    required this.activo,
  });

  Area copyWith({
    int? id,
    String? nombre,
    String? prefijo,
    String? logoUrl,
    bool? activo,
  }) {
    return Area(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      prefijo: prefijo ?? this.prefijo,
      logoUrl: logoUrl ?? this.logoUrl,
      activo: activo ?? this.activo,
    );
  }
}
