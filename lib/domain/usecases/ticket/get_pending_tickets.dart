import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/ticket.dart';
import '../../repositories/ticket_repository.dart';

class GetPendingTickets {
  final TicketRepository repository;

  GetPendingTickets(this.repository);

  Future<Either<Failure, List<Ticket>>> call(int areaId) {
    return repository.getPendingTickets(areaId);
  }
}
