import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/ticket_model.dart';

class TicketLocalDataSource {
  static const _pendingKey = 'pending_tickets';
  static const _lastTicketKey = 'last_ticket';
  static const _pendingTimestampKey = 'pending_tickets_ts';
  static const Duration _cacheTtl = Duration(minutes: 2);

  Future<void> cachePendingTickets(int areaId, List<TicketModel> tickets) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(tickets.map((t) => t.toJson()).toList());
    await prefs.setString('${_pendingKey}_$areaId', json);
    await prefs.setInt('${_pendingTimestampKey}_$areaId', DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<TicketModel>?> getCachedPendingTickets(int areaId) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('${_pendingTimestampKey}_$areaId');
    if (ts == null) return null;
    final elapsed = DateTime.now().millisecondsSinceEpoch - ts;
    if (elapsed > _cacheTtl.inMilliseconds) {
      await _clearPendingCache(areaId);
      return null;
    }
    final json = prefs.getString('${_pendingKey}_$areaId');
    if (json == null) return null;
    final list = jsonDecode(json) as List;
    return list.map((e) => TicketModel.fromJson(e)).toList();
  }

  Future<void> saveLastTicket(TicketModel ticket) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTicketKey, jsonEncode(ticket.toJson()));
  }

  Future<TicketModel?> getLastTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_lastTicketKey);
    if (json == null) return null;
    return TicketModel.fromJson(jsonDecode(json));
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_pendingKey) || k.startsWith(_pendingTimestampKey));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> _clearPendingCache(int areaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_pendingKey}_$areaId');
    await prefs.remove('${_pendingTimestampKey}_$areaId');
  }
}
