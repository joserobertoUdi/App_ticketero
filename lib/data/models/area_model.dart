import '../../domain/entities/area.dart';

class AreaModel {
  final int id;
  final String nombre;
  final String prefijo;
  final String logoUrl;
  final bool activo;

  const AreaModel({
    required this.id,
    required this.nombre,
    required this.prefijo,
    this.logoUrl = '',
    required this.activo,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      prefijo: json['prefijo'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'prefijo': prefijo,
      'logoUrl': logoUrl,
      'activo': activo,
    };
  }

  Area toEntity() {
    return Area(
      id: id,
      nombre: nombre,
      prefijo: prefijo,
      logoUrl: logoUrl,
      activo: activo,
    );
  }

  static AreaModel fromEntity(Area entity) {
    return AreaModel(
      id: entity.id,
      nombre: entity.nombre,
      prefijo: entity.prefijo,
      logoUrl: entity.logoUrl,
      activo: entity.activo,
    );
  }
}
