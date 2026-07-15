import '../../core/enums/ticket_status.dart';
import '../../core/enums/ticket_type.dart';
import '../../domain/entities/ticket.dart';

class TicketModel {
  final int id;
  final String codigoTicket;
  final String tipoTicket;
  final int areaId;
  final String areaNombre;
  final String status;
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

  const TicketModel({
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

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as int? ?? 0,
      codigoTicket: json['codigoTicket'] as String? ?? '',
      tipoTicket: json['tipoTicket'] as String? ?? 'caja',
      areaId: json['areaId'] as int? ?? 0,
      areaNombre: json['areaNombre'] as String? ?? '',
      status: json['status'] as String? ?? 'pendiente',
      llamadoPorUserId: json['llamadoPorUserId'] as int?,
      llamadoPorUserName: json['llamadoPorUserName'] as String?,
      createdAt: DateTime.parse(json['creadoEn'] as String? ??
          json['createdAt'] as String? ??
          DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tiempoEsperaSegundos: json['tiempoEsperaSegundos'] as int?,
      tiempoAtencionSegundos: json['tiempoAtencionSegundos'] as int?,
      tiempoAtencionFormateado: json['tiempoAtencionFormateado'] as String?,
      prioridad: json['prioridad'] as int? ?? 0,
      derivadoDe: json['derivadoDe'] as String?,
      derivadoDeNombre: json['derivadoDeNombre'] as String?,
      observacion: json['observacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigoTicket': codigoTicket,
      'tipoTicket': tipoTicket,
      'areaId': areaId,
      'areaNombre': areaNombre,
      'status': status,
      'llamadoPorUserId': llamadoPorUserId,
      'creadoEn': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tiempoEsperaSegundos': tiempoEsperaSegundos,
      'tiempoAtencionSegundos': tiempoAtencionSegundos,
      'tiempoAtencionFormateado': tiempoAtencionFormateado,
      'prioridad': prioridad,
      'derivadoDe': derivadoDe,
      'derivadoDeNombre': derivadoDeNombre,
      'observacion': observacion,
    };
  }

  Ticket toEntity() {
    return Ticket(
      id: id,
      codigoTicket: codigoTicket,
      tipoTicket: TicketType.fromApiValue(tipoTicket),
      areaId: areaId,
      areaNombre: areaNombre,
      status: TicketStatus.fromApiValue(status),
      llamadoPorUserId: llamadoPorUserId,
      llamadoPorUserName: llamadoPorUserName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tiempoEsperaSegundos: tiempoEsperaSegundos,
      tiempoAtencionSegundos: tiempoAtencionSegundos,
      tiempoAtencionFormateado: tiempoAtencionFormateado,
      prioridad: prioridad,
      derivadoDe: derivadoDe,
      derivadoDeNombre: derivadoDeNombre,
      observacion: observacion,
    );
  }

  static TicketModel fromEntity(Ticket entity) {
    return TicketModel(
      id: entity.id,
      codigoTicket: entity.codigoTicket,
      tipoTicket: entity.tipoTicket.apiValue,
      areaId: entity.areaId,
      areaNombre: entity.areaNombre,
      status: entity.status.apiValue,
      llamadoPorUserId: entity.llamadoPorUserId,
      llamadoPorUserName: entity.llamadoPorUserName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      tiempoEsperaSegundos: entity.tiempoEsperaSegundos,
      tiempoAtencionSegundos: entity.tiempoAtencionSegundos,
      tiempoAtencionFormateado: entity.tiempoAtencionFormateado,
      prioridad: entity.prioridad,
      derivadoDe: entity.derivadoDe,
      derivadoDeNombre: entity.derivadoDeNombre,
      observacion: entity.observacion,
    );
  }
}
