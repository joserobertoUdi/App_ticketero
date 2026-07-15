import 'models/cached_user.dart';
import 'models/cached_area.dart';
import 'models/cached_ticket.dart';

class DataStore {
  static final DataStore _instance = DataStore._internal();
  static DataStore get instance => _instance;
  DataStore._internal();

  final List<CachedUser> users = [];
  final List<CachedArea> areas = [];
  final List<CachedTicket> tickets = [];
  int _nextUserId = 10;
  int _nextAreaId = 10;
  int _nextTicketId = 100;
  final Map<int, int> _nextTicketNumByArea = {};

  int get nextUserId => _nextUserId++;
  int get nextAreaId => _nextAreaId++;
  int get nextTicketId => _nextTicketId++;

  String _nextTicketCode(int areaId) {
    final num = (_nextTicketNumByArea[areaId] ?? 0) + 1;
    _nextTicketNumByArea[areaId] = num;
    return num.toString().padLeft(3, '0');
  }

  void reset() {
    users.clear();
    areas.clear();
    tickets.clear();
    _nextUserId = 10;
    _nextAreaId = 10;
    _nextTicketId = 100;
    _nextTicketNumByArea.clear();
  }

  List<CachedUser> get activeUsers => users.where((u) => u.activo).toList();
  List<CachedArea> get activeAreas => areas.where((a) => a.activo).toList();

  CachedUser? getUserByUsername(String username) {
    try { return users.firstWhere((u) => u.nombreUsuario == username); }
    catch (_) { return null; }
  }

  CachedUser? getUserById(int id) {
    try { return users.firstWhere((u) => u.id == id); }
    catch (_) { return null; }
  }

  void addUser(CachedUser user) => users.add(user);
  void updateUser(CachedUser user) {
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx != -1) users[idx] = user;
  }
  void deleteUser(int id) { users.removeWhere((u) => u.id == id); }

  void addArea(CachedArea area) => areas.add(area);
  void deleteArea(int id) { areas.removeWhere((a) => a.id == id); }

  CachedTicket createTicket(int areaId, String prefijo, String areaNombre, String tipo, {int prioridad = 0, String? derivadoDe, String? derivadoDeNombre}) {
    final t = CachedTicket(
      codigo: '$prefijo-${_nextTicketCode(areaId)}',
      areaId: areaId,
      areaNombre: areaNombre,
      tipo: tipo,
      estado: 'pendiente',
      creado: DateTime.now(),
      prioridad: prioridad,
      derivadoDe: derivadoDe,
      derivadoDeNombre: derivadoDeNombre,
    );

    if (prioridad > 0) {
      final firstPendingIdx = tickets.indexWhere((t) => t.estado == 'pendiente');
      if (firstPendingIdx != -1 && firstPendingIdx + 1 < tickets.length) {
        tickets.insert(firstPendingIdx + 1, t);
      } else if (firstPendingIdx != -1) {
        tickets.add(t);
      } else {
        tickets.insert(0, t);
      }
    } else {
      tickets.insert(0, t);
    }
    return t;
  }

  CachedTicket? deriveTicket(String codigoOrigen, int targetAreaId, String targetPrefijo, String targetAreaNombre, String tipo) {
    final sourceIdx = tickets.indexWhere((t) => t.codigo == codigoOrigen);
    if (sourceIdx == -1) return null;

    final source = tickets[sourceIdx];

    final fromArea = source.areaNombre;
    source.areaId = targetAreaId;
    source.areaNombre = targetAreaNombre;
    source.tipo = tipo;
    source.estado = 'pendiente';
    source.prioridad = 1;
    source.derivadoDe = codigoOrigen;
    source.derivadoDeNombre = fromArea;

    tickets.removeAt(sourceIdx);
    final firstPendingIdx = tickets.indexWhere((t) => t.estado == 'pendiente');
    if (firstPendingIdx != -1 && firstPendingIdx + 1 < tickets.length) {
      tickets.insert(firstPendingIdx + 1, source);
    } else if (firstPendingIdx != -1) {
      tickets.add(source);
    } else {
      tickets.insert(0, source);
    }

    return source;
  }

  List<CachedTicket> get pendingTickets {
    final sorted = List<CachedTicket>.from(tickets.where((t) => t.estado == 'pendiente'));
    sorted.sort((a, b) {
      if (a.prioridad != b.prioridad) return b.prioridad.compareTo(a.prioridad);
      return a.creado.compareTo(b.creado);
    });
    return sorted;
  }

  List<CachedTicket> get calledTickets => tickets.where((t) => t.estado == 'llamado' || t.estado == 'en_atencion').toList();
  List<CachedTicket> get completedTickets => tickets.where((t) => t.estado == 'completado').toList();

  CachedTicket? callNextTicket(int userId, {int? areaId}) {
    var pending = pendingTickets;
    if (areaId != null) {
      pending = pending.where((t) => t.areaId == areaId).toList();
    }
    if (pending.isEmpty) return null;

    if (areaId != null) {
      final normales = pending.where((t) => t.prioridad == 0).toList();
      final prioritarios = pending.where((t) => t.prioridad > 0).toList();

      if (normales.isNotEmpty) {
        final ticket = normales.first;
        ticket.estado = 'llamado';
        ticket.llamadoEn = DateTime.now();
        ticket.llamadoPorUserId = userId;
        return ticket;
      }
      if (prioritarios.isNotEmpty) {
        final ticket = prioritarios.first;
        ticket.estado = 'llamado';
        ticket.llamadoEn = DateTime.now();
        ticket.llamadoPorUserId = userId;
        return ticket;
      }
    }

    final ticket = pending.first;
    ticket.estado = 'llamado';
    ticket.llamadoEn = DateTime.now();
    ticket.llamadoPorUserId = userId;
    return ticket;
  }

  CachedTicket? startAttention(int ticketId, int userId) {
    CachedTicket? ticket;
    for (final t in tickets) {
      if (t.estado == 'llamado' && t.llamadoPorUserId == userId) {
        ticket = t;
        break;
      }
    }
    if (ticket == null) return null;
    ticket.estado = 'en_atencion';
    ticket.iniciadoEn = DateTime.now();
    ticket.iniciadoPorUserId = userId;
    return ticket;
  }

  CachedTicket? completeTicket(String codigo) {
    final idx = tickets.indexWhere((t) => t.codigo == codigo);
    if (idx == -1) return null;
    tickets[idx].estado = 'completado';
    return tickets[idx];
  }
}
