import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/ticket.dart';
import '../../repositories/ticket_repository.dart';

class CompleteTicket {
  final TicketRepository repository;

  CompleteTicket(this.repository);

  Future<Either<Failure, Ticket>> call(
      int ticketId, int userId, String? observacion) {
    return repository.completeAttention(ticketId, userId, observacion);
  }
}
