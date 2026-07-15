import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';

const _callerChannelName = 'sistema_ticketero/caller';

class CallerTicketState {
  final int? activeTicketId;
  final String? activeCodigo;
  final int? lastCalledTicketId;
  final String? lastCalledCodigo;
  final String? lastCalledArea;
  // Gap 11: incluir areaId y tipo de ticket reales en lugar de hardcodear 0 / incidente
  final int lastCalledAreaId;
  final String lastCalledTipoTicket;
  final String? lastCalledUserName;
  final bool lastCalledPriority;
  final String? lastCalledDerivadoDe;
  final String? lastCalledDerivadoDeNombre;
  final List<Map<String, dynamic>> recentCalls;
  final List<Map<String, dynamic>> history;
  final Set<String> historyCodigos;

  const CallerTicketState({
    this.activeTicketId,
    this.activeCodigo,
    this.lastCalledTicketId,
    this.lastCalledCodigo,
    this.lastCalledArea,
    this.lastCalledAreaId = 0,
    this.lastCalledTipoTicket = 'incidente',
    this.lastCalledUserName,
    this.lastCalledPriority = false,
    this.lastCalledDerivadoDe,
    this.lastCalledDerivadoDeNombre,
    this.recentCalls = const [],
    this.history = const [],
    this.historyCodigos = const {},
  });

  Map<String, dynamic> toJson() => {
        if (activeTicketId != null) 'activeTicketId': activeTicketId,
        'activeCodigo': activeCodigo,
        if (lastCalledTicketId != null) 'lastCalledTicketId': lastCalledTicketId,
        'lastCalledCodigo': lastCalledCodigo,
        'lastCalledArea': lastCalledArea,
        'lastCalledAreaId': lastCalledAreaId,
        'lastCalledTipoTicket': lastCalledTipoTicket,
        'lastCalledUserName': lastCalledUserName,
        'lastCalledPriority': lastCalledPriority,
        'lastCalledDerivadoDe': lastCalledDerivadoDe,
        'lastCalledDerivadoDeNombre': lastCalledDerivadoDeNombre,
        'recentCalls': recentCalls,
        'history': history,
        'historyCodigos': historyCodigos.toList(),
      };

  factory CallerTicketState.fromJson(Map<String, dynamic> json) =>
      CallerTicketState(
        activeTicketId: json['activeTicketId'] as int?,
        activeCodigo: json['activeCodigo'] as String?,
        lastCalledTicketId: json['lastCalledTicketId'] as int?,
        lastCalledCodigo: json['lastCalledCodigo'] as String?,
        lastCalledArea: json['lastCalledArea'] as String?,
        lastCalledAreaId: json['lastCalledAreaId'] as int? ?? 0,
        lastCalledTipoTicket: json['lastCalledTipoTicket'] as String? ?? 'incidente',
        lastCalledUserName: json['lastCalledUserName'] as String?,
        lastCalledPriority: json['lastCalledPriority'] as bool? ?? false,
        lastCalledDerivadoDe: json['lastCalledDerivadoDe'] as String?,
        lastCalledDerivadoDeNombre: json['lastCalledDerivadoDeNombre'] as String?,
        recentCalls: (json['recentCalls'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        history: (json['history'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        historyCodigos: (json['historyCodigos'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toSet() ??
            {},
      );
}

class CallerChannel {
  static const _channel = WindowMethodChannel(
    _callerChannelName,
    mode: ChannelMode.unidirectional,
  );

  static Future<void> sendState(CallerTicketState state) async {
    try {
      await _channel.invokeMethod('ticketState', jsonEncode(state.toJson()));
    } catch (_) {}
  }

  static Future<void> setHandler(
      void Function(CallerTicketState) onState) async {
    await _channel.setMethodCallHandler((call) async {
      if (call.method == 'ticketState') {
        final state = CallerTicketState.fromJson(
            jsonDecode(call.arguments as String) as Map<String, dynamic>);
        onState(state);
      }
    });
  }
}
