class AttentionLog {
  final int id;
  final int ticketId;
  final int userId;
  final String? userName;
  final String? codigoTicket;
  final int? areaId;
  final String? areaNombre;
  final DateTime llamadoAt;
  final DateTime? iniciadoAt;
  final DateTime? completadoAt;
  final int? tiempoSegundos;
  final String? observacion;

  const AttentionLog({
    required this.id,
    required this.ticketId,
    required this.userId,
    this.userName,
    this.codigoTicket,
    this.areaId,
    this.areaNombre,
    required this.llamadoAt,
    this.iniciadoAt,
    this.completadoAt,
    this.tiempoSegundos,
    this.observacion,
  });

  String get tiempoFormateado {
    if (tiempoSegundos == null) return '--:--';
    final minutos = tiempoSegundos! ~/ 60;
    final segundos = tiempoSegundos! % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  String get tiempoEsperaFormateado {
    final inicio = iniciadoAt;
    if (inicio == null) return '--:--';
    final espera = inicio.difference(llamadoAt);
    final minutos = espera.inMinutes;
    final segundos = espera.inSeconds % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }
}
