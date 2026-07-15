import '../../domain/entities/attention_log.dart';

class AttentionLogModel {
  final int id;
  final int ticketId;
  final int userId;
  final String? userName;
  final String? codigoTicket;
  final String llamadoAt;
  final String? iniciadoAt;
  final String? completadoAt;
  final int? tiempoSegundos;
  final String? observacion;

  const AttentionLogModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    this.userName,
    this.codigoTicket,
    required this.llamadoAt,
    this.iniciadoAt,
    this.completadoAt,
    this.tiempoSegundos,
    this.observacion,
  });

  factory AttentionLogModel.fromJson(Map<String, dynamic> json) {
    return AttentionLogModel(
      id: json['id'] as int,
      ticketId: json['ticketId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String?,
      codigoTicket: json['codigoTicket'] as String?,
      llamadoAt: json['llamadoAt'] as String? ??
          json['llamadoEn'] as String? ??
          DateTime.now().toIso8601String(),
      iniciadoAt: json['iniciadoAt'] as String? ??
          json['iniciadoEn'] as String?,
      completadoAt: json['completadoAt'] as String? ??
          json['completadoEn'] as String?,
      tiempoSegundos: json['tiempoSegundos'] as int? ??
          json['tiempoAtencionSegundos'] as int?,
      observacion: json['observacion'] as String?,
    );
  }

  AttentionLog toEntity() {
    return AttentionLog(
      id: id,
      ticketId: ticketId,
      userId: userId,
      userName: userName,
      codigoTicket: codigoTicket,
      llamadoAt: DateTime.parse(llamadoAt),
      iniciadoAt: iniciadoAt != null ? DateTime.parse(iniciadoAt!) : null,
      completadoAt:
          completadoAt != null ? DateTime.parse(completadoAt!) : null,
      tiempoSegundos: tiempoSegundos,
      observacion: observacion,
    );
  }
}
