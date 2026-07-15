import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/local/ticket_local_datasource.dart';
import '../../data/datasources/remote/ticket_remote_datasource.dart';
import '../../data/models/ticket_model.dart';
import '../../domain/entities/attention_log.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource _remote;
  final TicketLocalDataSource _local;

  TicketRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, Ticket>> createTicket(int areaId, {int? servicioId, int? tipoTicketId, int? prioridadId, String? descripcion}) async {
    try {
      final model = await _remote.createTicket(areaId, servicioId: servicioId, tipoTicketId: tipoTicketId, prioridadId: prioridadId, descripcion: descripcion);
      await _local.saveLastTicket(model);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al crear ticket: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Ticket>>> getPendingTickets(int areaId) async {
    try {
      final models = await _remote.getPendingTickets(areaId);
      await _local.cachePendingTickets(areaId, models);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      try {
        final cached = await _local.getCachedPendingTickets(areaId);
        if (cached != null) {
          return Right(cached.map((m) => m.toEntity()).toList());
        }
      } catch (_) {}
      return Left(ServerFailure(message: 'Error al obtener pendientes: $e'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> callTicket(int ticketId, [int userId = 0]) async {
    try {
      final model = await _remote.callTicket(ticketId, userId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al llamar ticket: $e'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> callNextTicket(int areaId) async {
    try {
      final pending = await getPendingTickets(areaId);
      return pending.fold(
        (failure) => Left(failure),
        (tickets) {
          if (tickets.isEmpty) {
            return Left(
                ServerFailure(message: 'No hay tickets pendientes'));
          }
          return callTicket(tickets.first.id);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Error al llamar siguiente ticket: $e'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> startAttention(
      int ticketId, int userId, {int puestoId = 1}) async {
    try {
      final model = await _remote.startAttention(ticketId, userId, puestoId: puestoId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al iniciar atencion: $e'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> completeAttention(
      int ticketId, int userId, String? observacion) async {
    try {
      final model =
          await _remote.completeTicket(ticketId, userId, observacion);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al completar ticket: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deriveTicket(int ticketId, int atencionId, int targetAreaId, String? observacion) async {
    try {
      await _remote.deriveTicket(ticketId, atencionId, targetAreaId, observacion);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al derivar ticket: $e'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> cancelTicket(
      int ticketId, String? motivo) async {
    try {
      final model = await _remote.cancelTicket(ticketId, motivo);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al cancelar ticket: $e'));
    }
  }

  @override
  Future<Either<Failure, Ticket?>> getCurrentTicket(int userId) async {
    try {
      final model = await _remote.getCurrentTicket(userId);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener ticket actual: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AttentionLog>>> getAttentionHistory(
      int userId, DateTime fecha) async {
    try {
      final result = await _remote.getHistory(userId, fecha);
      final list = (result['tickets'] as List?) ?? [];
      final logs = list.map((e) {
        final t = TicketModel.fromJson(e);
        return AttentionLog(
          id: t.id,
          ticketId: t.id,
          userId: userId,
          codigoTicket: t.codigoTicket,
          areaId: t.areaId,
          areaNombre: t.areaNombre,
          llamadoAt: t.createdAt,
          iniciadoAt: null,
          completadoAt: t.updatedAt,
          tiempoSegundos: t.tiempoAtencionSegundos,
          observacion: t.observacion,
        );
      }).toList();
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener historial: $e'));
    }
  }
}
