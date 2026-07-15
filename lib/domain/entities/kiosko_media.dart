class KioskoMedia {
  final int id;
  final String nombre;
  final Set<int> areaIds;
  final String logoUrl;
  final String videoUrl;

  const KioskoMedia({
    required this.id,
    required this.nombre,
    required this.areaIds,
    this.logoUrl = '',
    this.videoUrl = '',
  });

  KioskoMedia copyWith({
    int? id,
    String? nombre,
    Set<int>? areaIds,
    String? logoUrl,
    String? videoUrl,
    bool clearLogo = false,
    bool clearVideo = false,
  }) {
    return KioskoMedia(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      areaIds: areaIds ?? this.areaIds,
      logoUrl: clearLogo ? '' : (logoUrl ?? this.logoUrl),
      videoUrl: clearVideo ? '' : (videoUrl ?? this.videoUrl),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'areaIds': areaIds.toList(),
        'logoUrl': logoUrl,
        'videoUrl': videoUrl,
      };

  factory KioskoMedia.fromJson(Map<String, dynamic> json) => KioskoMedia(
        id: json['id'] as int,
        nombre: (json['nombre'] as String?) ?? '',
        areaIds: json['areaIds'] != null
            ? (json['areaIds'] as List).cast<int>().toSet()
            : <int>{},
        logoUrl: (json['logoUrl'] as String?) ?? '',
        videoUrl: (json['videoUrl'] as String?) ?? '',
      );
}
