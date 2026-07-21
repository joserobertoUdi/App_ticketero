import 'package:flutter/foundation.dart';

import '../../core/enums/ticket_status.dart';
import '../../core/enums/ticket_type.dart';
import '../../core/printing/ticket_print_data.dart';
import '../../core/utils/time_sync_service.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/attention_log.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../window/ticket_channel.dart';

class RecentCall {
  final String codigoTicket;
  final String areaNombre;
  final int areaId;
  final DateTime calledAt;
  final int prioridad;
  final String? derivadoDe;
  final String? puesto;
  final String status;
  final String? operadorNombre;

  const RecentCall({
    required this.codigoTicket,
    required this.areaNombre,
    required this.areaId,
    required this.calledAt,
    this.prioridad = 0,
    this.derivadoDe,
    this.puesto,
    this.status = 'pendiente',
    this.operadorNombre,
  });
}

class TicketProvider extends ChangeNotifier {
  final TicketRepository _ticketRepository;
  final TimeSyncService _timeSync;

  Ticket? _currentTicket;
  Ticket? _activeAttention;
  Ticket? _lastCalledTicket;
  final List<Ticket> _pendingTickets = [];
  final List<AttentionLog> _attentionHistory = [];
  final List<RecentCall> _recentCalls = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _attentionStartedAt;
  bool _updatingFromChannel = false;
  TicketProvider({required this._ticketRepository, TimeSyncService? timeSync})
      : _timeSync = timeSync ?? TimeSyncService();

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (!_updatingFromChannel) {
      broadcastToCaller();
    }
  }

  Ticket? get currentTicket => _currentTicket;
  Ticket? get activeAttention => _activeAttention;
  Ticket? get lastCalledTicket => _lastCalledTicket;
  List<Ticket> get pendingTickets => List.unmodifiable(_pendingTickets);
  List<AttentionLog> get attentionHistory =>
      List.unmodifiable(_attentionHistory);
  List<RecentCall> get recentCalls => List.unmodifiable(_recentCalls);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingCount => _pendingTickets.length;

  int pendingCountForArea(int areaId) =>
      _pendingTickets.where((t) => t.areaId == areaId).length;

  int pendingCountForAreas(List<int> areaIds) =>
      _pendingTickets.where((t) => areaIds.contains(t.areaId)).length;

  Future<void> refreshPendingForAreas(List<int> areaIds) async {
    _pendingTickets.clear();
    for (final areaId in areaIds) {
      final result = await _ticketRepository.getPendingTickets(areaId);
      result.fold((_) {}, (tickets) => _pendingTickets.addAll(tickets));
    }
    notifyListeners();
  }

  List<Ticket> pendingTicketsForArea(int areaId) =>
      _pendingTickets.where((t) => t.areaId == areaId).toList();

  List<Ticket> pendingTicketsForAreas(List<int> areaIds) =>
      _pendingTickets.where((t) => areaIds.contains(t.areaId)).toList();

  List<Ticket> get pendingPrioritarios =>
      _pendingTickets.where((t) => t.esPrioritario).toList();

  Future<bool> createTicket(int areaId, {String? areaName, int? servicioId, int? tipoTicketId, int? prioridadId, String? descripcion}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _ticketRepository.createTicket(areaId, servicioId: servicioId, tipoTicketId: tipoTicketId, prioridadId: prioridadId, descripcion: descripcion);
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (ticket) {
          _currentTicket = ticket;
          _pendingTickets.add(ticket);
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al crear ticket';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Ticket> buildQueueForArea(int areaId) {
    final areaTickets = _pendingTickets.where((t) => t.areaId == areaId).toList();
    areaTickets.sort((a, b) {
      if (a.prioridad != b.prioridad) return b.prioridad.compareTo(a.prioridad);
      return a.createdAt.compareTo(b.createdAt);
    });

    final result = <Ticket>[];
    final normales = areaTickets.where((t) => !t.esPrioritario).toList();
    final prioritarios = areaTickets.where((t) => t.esPrioritario).toList();
    result.addAll(prioritarios);
    result.addAll(normales);
    return result;
  }

  Future<bool> callNextTicket(int areaId, {String? puesto, int userId = 0}) async {
    _isLoading = true;
    notifyListeners();

    var queue = buildQueueForArea(areaId);
    if (queue.isEmpty) {
      final result = await _ticketRepository.getPendingTickets(areaId);
      result.fold(
        (_) {},
        (tickets) {
          _pendingTickets.addAll(tickets);
          notifyListeners();
        },
      );
      queue = buildQueueForArea(areaId);
    }

    if (queue.isEmpty) {
      _errorMessage = 'No hay tickets pendientes';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final nextTicket = queue.first;
      final result = await _ticketRepository.callTicket(nextTicket.id, userId);
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (ticket) {
          _pendingTickets.removeWhere((t) => t.id == ticket.id);
          _lastCalledTicket = ticket;
          _activeAttention = ticket;
          _recentCalls.insert(
            0,
            RecentCall(
              codigoTicket: ticket.codigoTicket,
              areaNombre: ticket.areaNombre,
              areaId: ticket.areaId,
              calledAt: _timeSync.serverNow(),
              prioridad: ticket.prioridad,
              derivadoDe: ticket.derivadoDe,
              puesto: puesto,
              status: ticket.status.name,
              operadorNombre: ticket.llamadoPorUserName,
            ),
          );
          if (_recentCalls.length > 20) {
            _recentCalls.removeRange(20, _recentCalls.length);
          }
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al llamar ticket';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> startAttention(int ticketId, int userId, {int puestoId = 1}) async {
    if (_activeAttention == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _ticketRepository.startAttention(ticketId, userId, puestoId: puestoId);
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (_) {
          _activeAttention = _activeAttention!.copyWith(
            status: TicketStatus.en_atencion,
          );
          _attentionStartedAt = _timeSync.serverNow();
          _updateRecentCallStatus(_activeAttention!.codigoTicket, 'en_atencion');
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al iniciar atención';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _updateRecentCallStatus(String codigoTicket, String newStatus) {
    final idx = _recentCalls.indexWhere((r) => r.codigoTicket == codigoTicket);
    if (idx == -1) return;
    final old = _recentCalls[idx];
    _recentCalls[idx] = RecentCall(
      codigoTicket: old.codigoTicket,
      areaNombre: old.areaNombre,
      areaId: old.areaId,
      calledAt: old.calledAt,
      prioridad: old.prioridad,
      derivadoDe: old.derivadoDe,
      puesto: old.puesto,
      status: newStatus,
      operadorNombre: old.operadorNombre,
    );
  }

  Future<bool> completeAttention(int ticketId, int userId, String? observacion) async {
    if (_activeAttention == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _ticketRepository.completeAttention(ticketId, userId, observacion);
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (ticket) {
          // Gap 12: usar tiempoAtencionSegundos que devuelve el servidor
          // en lugar de calcular con reloj local (puede diferir por zona horaria)
          final serverNow = _timeSync.serverNow();
          final duracion = ticket.tiempoAtencionSegundos
              ?? (_attentionStartedAt != null
                  ? serverNow.difference(_attentionStartedAt!).inSeconds
                  : 0);

          _activeAttention = _activeAttention!.copyWith(
            status: TicketStatus.completado,
          );

          _attentionHistory.insert(
            0,
            AttentionLog(
              // Gap 12: usar el id real del ticket como referencia en lugar de timestamp
              id: ticket.id,
              ticketId: _activeAttention!.id,
              userId: userId,
              codigoTicket: _activeAttention!.codigoTicket,
              areaId: _activeAttention!.areaId,
              areaNombre: _activeAttention!.areaNombre,
              llamadoAt: _activeAttention!.createdAt,
              completadoAt: serverNow,
              observacion: observacion,
              tiempoSegundos: duracion,
            ),
          );

          _activeAttention = null;
          _attentionStartedAt = null;
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al completar atención';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearAttention() {
    _activeAttention = null;
    _attentionStartedAt = null;
    notifyListeners();
  }

  TicketPrintData? getPrintData(int tiempoEstimadoPorTicket, int personasEnCola) {
    final ticket = _currentTicket;
    if (ticket == null) return null;

    final now = _timeSync.serverNow().toLocal();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final esperaTotalMin = tiempoEstimadoPorTicket * personasEnCola;

    return TicketPrintData(
      ticketCode: ticket.codigoTicket,
      areaName: ticket.areaNombre,
      dateTime: dateStr,
      estimatedWait: '$esperaTotalMin min',
      barcodeData: ticket.codigoTicket,
    );
  }

  void clearCurrentTicket() {
    _currentTicket = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> deriveTicket(int ticketId, int targetAreaId, String? observacion) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _ticketRepository.deriveTicket(ticketId, 0, targetAreaId, observacion);
      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (_) {
          _activeAttention = null;
          _attentionStartedAt = null;
          _lastCalledTicket = null;
          _isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Error al derivar ticket';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  CallerTicketState toCallerState() => CallerTicketState(
        activeTicketId: _activeAttention?.id,
        activeCodigo: _activeAttention?.codigoTicket,
        lastCalledTicketId: _lastCalledTicket?.id,
        lastCalledCodigo: _lastCalledTicket?.codigoTicket,
        lastCalledArea: _lastCalledTicket?.areaNombre,
        // Gap 11: propagar areaId y tipoTicket reales
        lastCalledAreaId: _lastCalledTicket?.areaId ?? 0,
        lastCalledTipoTicket: _lastCalledTicket?.tipoTicket.name ?? 'incidente',
        lastCalledUserName: _lastCalledTicket?.llamadoPorUserName,
        lastCalledPriority: _lastCalledTicket?.esPrioritario ?? false,
        lastCalledDerivadoDe: _lastCalledTicket?.derivadoDe,
        lastCalledDerivadoDeNombre: _lastCalledTicket?.derivadoDeNombre,
        recentCalls: _recentCalls
            .map((r) => {
                  'codigoTicket': r.codigoTicket,
                  'areaNombre': r.areaNombre,
                  'areaId': r.areaId,
                  'calledAt': r.calledAt.toIso8601String(),
                  'prioridad': r.prioridad,
                  'derivadoDe': r.derivadoDe,
                  'puesto': r.puesto,
                  'status': r.status,
                  'operadorNombre': r.operadorNombre,
                })
            .toList(),
        history: _attentionHistory
            .map((h) => {
                  'id': h.id,
                  'codigoTicket': h.codigoTicket,
                  'areaId': h.areaId,
                  'areaNombre': h.areaNombre,
                  'observacion': h.observacion,
                  'tiempoSegundos': h.tiempoSegundos,
                })
            .toList(),
        historyCodigos:
            _attentionHistory.map((h) => h.codigoTicket).whereType<String>().toSet(),
      );

  void updateFromChannel(CallerTicketState state) {
    _updatingFromChannel = true;

    _activeAttention = null;
    _lastCalledTicket = null;
    _recentCalls.clear();
    _attentionHistory.clear();

    if (state.activeCodigo != null || state.lastCalledCodigo != null) {
      // Gap 11: usar areaId y tipoTicket reales del state en lugar de hardcodear
      final tipoTicket = TicketType.values.firstWhere(
        (t) => t.name == state.lastCalledTipoTicket,
        orElse: () => TicketType.incidente,
      );
      _lastCalledTicket = Ticket(
        id: state.lastCalledTicketId ?? _timeSync.serverNow().millisecondsSinceEpoch,
        codigoTicket: state.lastCalledCodigo ?? state.activeCodigo ?? '',
        tipoTicket: tipoTicket,
        areaId: state.lastCalledAreaId,
        areaNombre: state.lastCalledArea ?? '',
        llamadoPorUserName: state.lastCalledUserName,
        status: TicketStatus.pendiente,
        createdAt: _timeSync.serverNow(),
        prioridad: state.lastCalledPriority ? 1 : 0,
        derivadoDe: state.lastCalledDerivadoDe,
        derivadoDeNombre: state.lastCalledDerivadoDeNombre,
      );
      if (state.activeCodigo != null) {
        _activeAttention = Ticket(
          id: state.activeTicketId ?? state.lastCalledTicketId ?? _timeSync.serverNow().millisecondsSinceEpoch,
          codigoTicket: state.activeCodigo ?? '',
          tipoTicket: tipoTicket,
          areaId: state.lastCalledAreaId,
          areaNombre: state.lastCalledArea ?? '',
          llamadoPorUserName: state.lastCalledUserName,
        status: TicketStatus.en_atencion,
        createdAt: _timeSync.serverNow(),
          prioridad: state.lastCalledPriority ? 1 : 0,
          derivadoDe: state.lastCalledDerivadoDe,
          derivadoDeNombre: state.lastCalledDerivadoDeNombre,
        );
      }
    }

    for (final r in state.recentCalls) {
      _recentCalls.add(RecentCall(
        codigoTicket: r['codigoTicket'] as String? ?? '',
        areaNombre: r['areaNombre'] as String? ?? '',
        areaId: r['areaId'] as int? ?? 0,
        calledAt: DateTime.tryParse(r['calledAt'] as String? ?? '') ?? _timeSync.serverNow(),
        prioridad: r['prioridad'] as int? ?? 0,
        derivadoDe: r['derivadoDe'] as String?,
        puesto: r['puesto'] as String?,
        status: r['status'] as String? ?? 'llamado',
      ));
    }

    for (final h in state.history) {
      _attentionHistory.add(AttentionLog(
        id: h['id'] as int? ?? 0,
        ticketId: 0,
        userId: 0,
        codigoTicket: h['codigoTicket'] as String?,
        areaId: h['areaId'] as int?,
        areaNombre: h['areaNombre'] as String?,
        llamadoAt: _timeSync.serverNow(),
        observacion: h['observacion'] as String?,
        tiempoSegundos: h['tiempoSegundos'] as int?,
      ));
    }

    notifyListeners();
  }

  void broadcastToCaller() {
    CallerChannel.sendState(toCallerState());
  }
}
