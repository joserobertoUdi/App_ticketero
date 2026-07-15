class CachedTicket {
  final String codigo;
  int areaId;
  String areaNombre;
  String tipo;
  String estado;
  final DateTime creado;
  DateTime? llamadoEn;
  int? llamadoPorUserId;
  int prioridad;
  String? derivadoDe;
  String? derivadoDeNombre;
  int? iniciadoPorUserId;
  DateTime? iniciadoEn;

  CachedTicket({
    required this.codigo,
    required this.areaId,
    required this.areaNombre,
    required this.tipo,
    required this.estado,
    required this.creado,
    this.llamadoEn,
    this.llamadoPorUserId,
    this.prioridad = 0,
    this.derivadoDe,
    this.derivadoDeNombre,
    this.iniciadoPorUserId,
    this.iniciadoEn,
  });

  bool get esPrioritario => prioridad > 0;
  bool get esDerivado => derivadoDe != null;
}
