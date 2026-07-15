import '../../domain/entities/activo_fijo.dart';

class ActivoFijoModel {
  final int id;
  final String tipoActivo;
  final String numeroActivo;
  final String? descripcion;
  final String? marca;
  final String? modelo;
  final String? serie;

  const ActivoFijoModel({
    this.id = 0,
    required this.tipoActivo,
    required this.numeroActivo,
    this.descripcion,
    this.marca,
    this.modelo,
    this.serie,
  });

  factory ActivoFijoModel.fromJson(Map<String, dynamic> json) => ActivoFijoModel(
        id: json['id'] as int? ?? 0,
        tipoActivo: (json['tipoActivo'] as String?) ?? '',
        numeroActivo: (json['numeroActivo'] as String?) ?? '',
        descripcion: json['descripcion'] as String?,
        marca: json['marca'] as String?,
        modelo: json['modelo'] as String?,
        serie: json['serie'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != 0) 'id': id,
        'tipoActivo': tipoActivo,
        'numeroActivo': numeroActivo,
        if (descripcion != null) 'descripcion': descripcion,
        if (marca != null) 'marca': marca,
        if (modelo != null) 'modelo': modelo,
        if (serie != null) 'serie': serie,
      };

  ActivoFijo toEntity() => ActivoFijo(
        id: id,
        tipoActivo: tipoActivo,
        numeroActivo: numeroActivo,
        descripcion: descripcion,
        marca: marca,
        modelo: modelo,
        serie: serie,
      );

  factory ActivoFijoModel.fromEntity(ActivoFijo entity) => ActivoFijoModel(
        id: entity.id,
        tipoActivo: entity.tipoActivo,
        numeroActivo: entity.numeroActivo,
        descripcion: entity.descripcion,
        marca: entity.marca,
        modelo: entity.modelo,
        serie: entity.serie,
      );
}
