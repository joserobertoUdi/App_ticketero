import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/ticket.dart';
import '../entities/attention_log.dart';

abstract class TicketRepository {
  Future<Either<Failure, Ticket>> createTicket(int areaId, {int? servicioId, int? tipoTicketId, int? prioridadId, String? descripcion});

  Future<Either<Failure, List<Ticket>>> getPendingTickets(int areaId);

  Future<Either<Failure, Ticket>> callTicket(int ticketId, [int userId = 0]);

  Future<Either<Failure, Ticket>> callNextTicket(int areaId);

  Future<Either<Failure, Ticket>> startAttention(int ticketId, int userId, {int puestoId = 1});

  Future<Either<Failure, Ticket>> completeAttention(
      int ticketId, int userId, String? observacion);

  Future<Either<Failure, void>> deriveTicket(int ticketId, int atencionId, int targetAreaId, String? observacion);

  Future<Either<Failure, Ticket>> cancelTicket(int ticketId, String? motivo);

  Future<Either<Failure, Ticket?>> getCurrentTicket(int userId);

  Future<Either<Failure, List<AttentionLog>>> getAttentionHistory(
      int userId, DateTime fecha);
}
