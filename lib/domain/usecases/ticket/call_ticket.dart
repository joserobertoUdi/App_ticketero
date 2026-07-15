import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/ticket.dart';
import '../../repositories/ticket_repository.dart';

class CallTicket {
  final TicketRepository repository;

  CallTicket(this.repository);

  Future<Either<Failure, Ticket>> call(int ticketId) {
    return repository.callTicket(ticketId);
  }
}
