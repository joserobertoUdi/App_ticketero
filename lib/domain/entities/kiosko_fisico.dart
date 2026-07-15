import 'activo_fijo.dart';

class KioskoFisico {
  final int id;
  final String nombre;
  final String ubicacion;
  final int ubicacionId;
  final String? ubicacionNombre;
  final int? kioskoMediaId;
  final bool activo;
  final bool esHuerfano;
  final List<int> areaIds;
  final String? ipKiosko;
  final List<ActivoFijo> activosFijos;
  final String? logoUrl;
  final String? videoUrl;

  final String? nombreImpresora;
  final String? puertoImpresora;
  final String? ipImpresora;
  final String? tipoConexionImpresora;
  final int anchoPapelMM;
  final int copias;
  final bool impresionAutomatica;

  final String? ipEquipo;
  final String? mascaraRedEquipo;
  final String? gatewayEquipo;
  final String? dnsEquipo;

  final String? tipoConexionRed;
  final bool dhcp;
  final String? direccionIP;
  final String? mascaraSubred;
  final String? gatewayRed;
  final String? dnsPrimario;
  final String? dnsSecundario;
  final int? puertoRed;

  const KioskoFisico({
    required this.id,
    required this.nombre,
    this.ubicacion = '',
    this.ubicacionId = 1,
    this.ubicacionNombre,
    this.kioskoMediaId,
    this.activo = true,
    this.esHuerfano = false,
    this.areaIds = const [],
    this.ipKiosko,
    this.activosFijos = const [],
    this.logoUrl,
    this.videoUrl,
    this.nombreImpresora,
    this.puertoImpresora,
    this.ipImpresora,
    this.tipoConexionImpresora,
    this.anchoPapelMM = 80,
    this.copias = 1,
    this.impresionAutomatica = true,
    this.ipEquipo,
    this.mascaraRedEquipo,
    this.gatewayEquipo,
    this.dnsEquipo,
    this.tipoConexionRed,
    this.dhcp = true,
    this.direccionIP,
    this.mascaraSubred,
    this.gatewayRed,
    this.dnsPrimario,
    this.dnsSecundario,
    this.puertoRed,
  });

  KioskoFisico copyWith({
    int? id,
    String? nombre,
    String? ubicacion,
    int? ubicacionId,
    String? ubicacionNombre,
    int? kioskoMediaId,
    bool? activo,
    bool? esHuerfano,
    List<int>? areaIds,
    String? ipKiosko,
    List<ActivoFijo>? activosFijos,
    String? logoUrl,
    String? videoUrl,
    String? nombreImpresora,
    String? puertoImpresora,
    String? ipImpresora,
    String? tipoConexionImpresora,
    int? anchoPapelMM,
    int? copias,
    bool? impresionAutomatica,
    String? ipEquipo,
    String? mascaraRedEquipo,
    String? gatewayEquipo,
    String? dnsEquipo,
    String? tipoConexionRed,
    bool? dhcp,
    String? direccionIP,
    String? mascaraSubred,
    String? gatewayRed,
    String? dnsPrimario,
    String? dnsSecundario,
    int? puertoRed,
  }) {
    return KioskoFisico(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      ubicacionId: ubicacionId ?? this.ubicacionId,
      ubicacionNombre: ubicacionNombre ?? this.ubicacionNombre,
      kioskoMediaId: kioskoMediaId ?? this.kioskoMediaId,
      activo: activo ?? this.activo,
      esHuerfano: esHuerfano ?? this.esHuerfano,
      areaIds: areaIds ?? this.areaIds,
      ipKiosko: ipKiosko ?? this.ipKiosko,
      activosFijos: activosFijos ?? this.activosFijos,
      logoUrl: logoUrl ?? this.logoUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      nombreImpresora: nombreImpresora ?? this.nombreImpresora,
      puertoImpresora: puertoImpresora ?? this.puertoImpresora,
      ipImpresora: ipImpresora ?? this.ipImpresora,
      tipoConexionImpresora: tipoConexionImpresora ?? this.tipoConexionImpresora,
      anchoPapelMM: anchoPapelMM ?? this.anchoPapelMM,
      copias: copias ?? this.copias,
      impresionAutomatica: impresionAutomatica ?? this.impresionAutomatica,
      ipEquipo: ipEquipo ?? this.ipEquipo,
      mascaraRedEquipo: mascaraRedEquipo ?? this.mascaraRedEquipo,
      gatewayEquipo: gatewayEquipo ?? this.gatewayEquipo,
      dnsEquipo: dnsEquipo ?? this.dnsEquipo,
      tipoConexionRed: tipoConexionRed ?? this.tipoConexionRed,
      dhcp: dhcp ?? this.dhcp,
      direccionIP: direccionIP ?? this.direccionIP,
      mascaraSubred: mascaraSubred ?? this.mascaraSubred,
      gatewayRed: gatewayRed ?? this.gatewayRed,
      dnsPrimario: dnsPrimario ?? this.dnsPrimario,
      dnsSecundario: dnsSecundario ?? this.dnsSecundario,
      puertoRed: puertoRed ?? this.puertoRed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'ubicacion': ubicacion,
        'ubicacionId': ubicacionId,
        'kioskoMediaId': kioskoMediaId,
        'activo': activo,
        'esHuerfano': esHuerfano,
        'areaIds': areaIds,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (ipKiosko != null) 'ipKiosko': ipKiosko,
        if (activosFijos.isNotEmpty) 'activosFijos': activosFijos.map((a) => a.toJson()).toList(),
        'nombreImpresora': nombreImpresora,
        'puertoImpresora': puertoImpresora,
        'ipImpresora': ipImpresora,
        'tipoConexionImpresora': tipoConexionImpresora,
        'anchoPapelMM': anchoPapelMM,
        'copias': copias,
        'impresionAutomatica': impresionAutomatica,
        'ipEquipo': ipEquipo,
        'mascaraRedEquipo': mascaraRedEquipo,
        'gatewayEquipo': gatewayEquipo,
        'dnsEquipo': dnsEquipo,
        'tipoConexionRed': tipoConexionRed,
        'dhcp': dhcp,
        'direccionIP': direccionIP,
        'mascaraSubred': mascaraSubred,
        'gatewayRed': gatewayRed,
        'dnsPrimario': dnsPrimario,
        'dnsSecundario': dnsSecundario,
        'puertoRed': puertoRed,
      };

  factory KioskoFisico.fromJson(Map<String, dynamic> json) => KioskoFisico(
        id: json['id'] as int,
        nombre: (json['nombre'] as String?) ?? '',
        ubicacion: (json['ubicacion'] as String?) ?? '',
        ubicacionId: (json['ubicacionId'] as int?) ?? 1,
        ubicacionNombre: json['ubicacionNombre'] as String?,
        kioskoMediaId: json['kioskoMediaId'] as int?,
        activo: (json['activo'] as bool?) ?? true,
        esHuerfano: (json['esHuerfano'] as bool?) ?? false,
        areaIds: json['areaIds'] != null
            ? (json['areaIds'] as List).cast<int>()
            : [],
        logoUrl: json['logoUrl'] as String?,
        videoUrl: json['videoUrl'] as String?,
        ipKiosko: json['ipKiosko'] as String?,
        activosFijos: json['activosFijos'] != null
            ? (json['activosFijos'] as List)
                .map((e) => ActivoFijo.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        nombreImpresora: json['nombreImpresora'] as String?,
        puertoImpresora: json['puertoImpresora'] as String?,
        ipImpresora: json['ipImpresora'] as String?,
        tipoConexionImpresora: json['tipoConexionImpresora'] as String?,
        anchoPapelMM: (json['anchoPapelMM'] as int?) ?? 80,
        copias: (json['copias'] as int?) ?? 1,
        impresionAutomatica: (json['impresionAutomatica'] as bool?) ?? true,
        ipEquipo: json['ipEquipo'] as String?,
        mascaraRedEquipo: json['mascaraRedEquipo'] as String?,
        gatewayEquipo: json['gatewayEquipo'] as String?,
        dnsEquipo: json['dnsEquipo'] as String?,
        tipoConexionRed: json['tipoConexionRed'] as String?,
        dhcp: (json['dhcp'] as bool?) ?? true,
        direccionIP: json['direccionIP'] as String?,
        mascaraSubred: json['mascaraSubred'] as String?,
        gatewayRed: json['gatewayRed'] as String?,
        dnsPrimario: json['dnsPrimario'] as String?,
        dnsSecundario: json['dnsSecundario'] as String?,
        puertoRed: json['puertoRed'] as int?,
      );
}
