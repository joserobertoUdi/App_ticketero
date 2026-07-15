class PuestoInfo {
  final int id;
  final String nombre;
  final int? occupiedByUserId;

  const PuestoInfo({
    required this.id,
    required this.nombre,
    this.occupiedByUserId,
  });

  PuestoInfo copyWith({
    int? id,
    String? nombre,
    int? occupiedByUserId,
    bool clearOccupied = false,
  }) {
    return PuestoInfo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      occupiedByUserId: clearOccupied ? null : (occupiedByUserId ?? this.occupiedByUserId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'occupiedByUserId': occupiedByUserId,
      };

  factory PuestoInfo.fromJson(Map<String, dynamic> json) => PuestoInfo(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        occupiedByUserId: json['occupiedByUserId'] as int? ??
            ((json['ocupado'] == true) ? 0 : null),
      );
}
