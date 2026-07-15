import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/ticket.dart';
import '../../repositories/ticket_repository.dart';

class CreateTicket {
  final TicketRepository repository;

  CreateTicket(this.repository);

  Future<Either<Failure, Ticket>> call(int areaId) {
    return repository.createTicket(areaId);
  }
}
