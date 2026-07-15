import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

class WebSocketService {
  HubConnection? _hubConnection;
  bool _isConnected = false;
  bool _intentionalDisconnect = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;
    _intentionalDisconnect = false;

    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(ApiConstants.websocketUrl)
          .withAutomaticReconnect()
          .build();

      _hubConnection!.on('TicketCreated', (data) {
        _eventController.add({'event': 'TicketCreated', 'data': data});
      });

      _hubConnection!.on('TicketCalled', (data) {
        _eventController.add({'event': 'TicketCalled', 'data': data});
      });

      _hubConnection!.on('TicketStarted', (data) {
        _eventController.add({'event': 'TicketStarted', 'data': data});
      });

      _hubConnection!.on('TicketCompleted', (data) {
        _eventController.add({'event': 'TicketCompleted', 'data': data});
      });

      _hubConnection!.on('TicketCancelled', (data) {
        _eventController.add({'event': 'TicketCancelled', 'data': data});
      });

      _hubConnection!.on('QueueUpdated', (data) {
        _eventController.add({'event': 'QueueUpdated', 'data': data});
      });

      _hubConnection!.onclose(({error}) {
        _isConnected = false;
        AppLogger.warn('WebSocket', 'Desconectado ${error?.toString() ?? ''}');
        if (!_intentionalDisconnect) {
          _scheduleReconnect();
        }
      });

      await _hubConnection!.start();
      _isConnected = true;
      _reconnectAttempts = 0;
      AppLogger.info('WebSocket', 'Conectado a ${ApiConstants.websocketUrl}');
    } catch (e) {
      _isConnected = false;
      AppLogger.error('WebSocket', 'Error al conectar', exception: e);
      if (!_intentionalDisconnect) {
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.error('WebSocket', 'Maximos reintentos alcanzados');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      seconds: (_reconnectAttempts * 2).clamp(1, 30),
    );

    AppLogger.info('WebSocket',
        'Reintentando en ${delay.inSeconds}s (intento $_reconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  Future<void> joinAreaGroup(int areaId) async {
    if (!_isConnected || _hubConnection == null) return;
    try {
      await _hubConnection!.invoke('JoinAreaGroup', args: [areaId]);
    } catch (e) {
      AppLogger.warn('WebSocket', 'Error al unirse al grupo $areaId');
    }
  }

  Future<void> leaveAreaGroup(int areaId) async {
    if (!_isConnected || _hubConnection == null) return;
    try {
      await _hubConnection!.invoke('LeaveAreaGroup', args: [areaId]);
    } catch (e) {
      AppLogger.warn('WebSocket', 'Error al salir del grupo $areaId');
    }
  }

  void on(String eventName, Function(dynamic) callback) {
    _eventController.stream
        .where((event) => event['event'] == eventName)
        .listen((event) {
      callback(event['data']);
    });
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _isConnected = false;

    try {
      await _hubConnection?.stop();
    } catch (_) {}
    _hubConnection = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
