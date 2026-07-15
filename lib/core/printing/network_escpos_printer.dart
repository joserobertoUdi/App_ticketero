import 'dart:io';
import 'dart:async';

import 'print_service.dart';
import 'ticket_print_data.dart';
import 'esc_pos_commands.dart';

class NetworkEscPosPrinter implements PrintService {
  final String host;
  final int port;
  final Duration timeout;

  Socket? _socket;
  bool _isConnected = false;

  NetworkEscPosPrinter({
    required this.host,
    this.port = 9100,
    this.timeout = const Duration(seconds: 5),
  });

  @override
  Future<bool> testConnection() async {
    try {
      final sock = await Socket.connect(host, port, timeout: timeout);
      await sock.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _connect() async {
    if (_isConnected && _socket != null) return;
    _socket = await Socket.connect(host, port, timeout: timeout);
    _isConnected = true;
  }

  Future<void> _disconnect() async {
    try {
      _isConnected = false;
      // Pequeña pausa para que la impresora termine de procesar los datos
      await Future.delayed(const Duration(milliseconds: 200));
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  @override
  Future<PrintResult> printTicket(TicketPrintData data) async {
    try {
      await _connect();
      if (_socket == null) {
        return PrintResult.error('No se pudo conectar a la impresora');
      }

      final bytes = EscPosCommands.buildTicketReceipt(
        headerText: data.header,
        ticketCode: data.ticketCode,
        areaName: data.areaName,
        dateTime: data.dateTime,
        estimatedWait: data.estimatedWait,
        instruction: data.instruction,
        footer: data.footer,
        barcodeData: data.barcodeData,
        qrData: data.ticketCode,
      );

      for (int i = 0; i < data.copies; i++) {
        _socket!.add(bytes);
      }

      await _socket!.flush();
      await _disconnect();

      return PrintResult.ok;
    } on SocketException catch (e) {
      await _disconnect();
      return PrintResult.error('Error de conexion: ${e.message}');
    } catch (e) {
      await _disconnect();
      return PrintResult.error('Error al imprimir: $e');
    }
  }

  @override
  Future<PrintResult> printRaw(List<int> bytes) async {
    try {
      await _connect();
      if (_socket == null) {
        return PrintResult.error('No se pudo conectar a la impresora');
      }

      _socket!.add(bytes);
      await _socket!.flush();
      await _disconnect();

      return PrintResult.ok;
    } catch (e) {
      await _disconnect();
      return PrintResult.error('Error al imprimir: $e');
    }
  }

  void dispose() {
    _disconnect();
  }
}
