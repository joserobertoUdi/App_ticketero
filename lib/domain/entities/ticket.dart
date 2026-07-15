import '../../core/enums/ticket_status.dart';
import '../../core/enums/ticket_type.dart';

class Ticket {
  final int id;
  final String codigoTicket;
  final TicketType tipoTicket;
  final int areaId;
  final String areaNombre;
  final TicketStatus status;
  final int? llamadoPorUserId;
  final String? llamadoPorUserName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final int? tiempoEsperaSegundos;
  final int? tiempoAtencionSegundos;
  final String? tiempoAtencionFormateado;

  final int prioridad;
  final String? derivadoDe;
  final String? derivadoDeNombre;
  final String? observacion;

  const Ticket({
    required this.id,
    required this.codigoTicket,
    required this.tipoTicket,
    required this.areaId,
    required this.areaNombre,
    required this.status,
    this.llamadoPorUserId,
    this.llamadoPorUserName,
    required this.createdAt,
    this.updatedAt,
    this.tiempoEsperaSegundos,
    this.tiempoAtencionSegundos,
    this.tiempoAtencionFormateado,
    this.prioridad = 0,
    this.derivadoDe,
    this.derivadoDeNombre,
    this.observacion,
  });

  bool get esPrioritario => prioridad <= 1;
  bool get esDerivado => derivadoDe != null;

  Ticket copyWith({
    int? id,
    String? codigoTicket,
    TicketType? tipoTicket,
    int? areaId,
    String? areaNombre,
    TicketStatus? status,
    int? llamadoPorUserId,
    String? llamadoPorUserName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? tiempoEsperaSegundos,
    int? tiempoAtencionSegundos,
    String? tiempoAtencionFormateado,
    int? prioridad,
    String? derivadoDe,
    String? derivadoDeNombre,
    String? observacion,
  }) {
    return Ticket(
      id: id ?? this.id,
      codigoTicket: codigoTicket ?? this.codigoTicket,
      tipoTicket: tipoTicket ?? this.tipoTicket,
      areaId: areaId ?? this.areaId,
      areaNombre: areaNombre ?? this.areaNombre,
      status: status ?? this.status,
      llamadoPorUserId: llamadoPorUserId ?? this.llamadoPorUserId,
      llamadoPorUserName: llamadoPorUserName ?? this.llamadoPorUserName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tiempoEsperaSegundos: tiempoEsperaSegundos ?? this.tiempoEsperaSegundos,
      tiempoAtencionSegundos: tiempoAtencionSegundos ?? this.tiempoAtencionSegundos,
      tiempoAtencionFormateado: tiempoAtencionFormateado ?? this.tiempoAtencionFormateado,
      prioridad: prioridad ?? this.prioridad,
      derivadoDe: derivadoDe ?? this.derivadoDe,
      derivadoDeNombre: derivadoDeNombre ?? this.derivadoDeNombre,
      observacion: observacion ?? this.observacion,
    );
  }
}
