class ActivoFijo {
  final int id;
  final String tipoActivo;
  final String numeroActivo;
  final String? descripcion;
  final String? marca;
  final String? modelo;
  final String? serie;

  const ActivoFijo({
    this.id = 0,
    required this.tipoActivo,
    required this.numeroActivo,
    this.descripcion,
    this.marca,
    this.modelo,
    this.serie,
  });

  ActivoFijo copyWith({
    int? id,
    String? tipoActivo,
    String? numeroActivo,
    String? descripcion,
    String? marca,
    String? modelo,
    String? serie,
  }) {
    return ActivoFijo(
      id: id ?? this.id,
      tipoActivo: tipoActivo ?? this.tipoActivo,
      numeroActivo: numeroActivo ?? this.numeroActivo,
      descripcion: descripcion ?? this.descripcion,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      serie: serie ?? this.serie,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipoActivo': tipoActivo,
        'numeroActivo': numeroActivo,
        'descripcion': descripcion,
        'marca': marca,
        'modelo': modelo,
        'serie': serie,
      };

  factory ActivoFijo.fromJson(Map<String, dynamic> json) => ActivoFijo(
        id: json['id'] as int? ?? 0,
        tipoActivo: (json['tipoActivo'] as String?) ?? '',
        numeroActivo: (json['numeroActivo'] as String?) ?? '',
        descripcion: json['descripcion'] as String?,
        marca: json['marca'] as String?,
        modelo: json['modelo'] as String?,
        serie: json['serie'] as String?,
      );
}
