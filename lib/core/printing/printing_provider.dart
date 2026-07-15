import 'package:flutter/foundation.dart';

import 'print_service.dart';
import 'network_escpos_printer.dart';
import 'windows_printer_service.dart';
import 'serial_escpos_printer.dart';
import 'ticket_print_data.dart';

enum PrinterType { network, windows, serial, disabled }

class PrintConfig {
  final PrinterType type;
  final String host;
  final int port;
  final String windowsPrinterName;
  final String comPort;
  final int baudRate;

  const PrintConfig({
    this.type = PrinterType.disabled,
    this.host = '',
    this.port = 9100,
    this.windowsPrinterName = '',
    this.comPort = '',
    this.baudRate = 19200,
  });

  PrintConfig copyWith({
    PrinterType? type,
    String? host,
    int? port,
    String? windowsPrinterName,
    String? comPort,
    int? baudRate,
  }) {
    return PrintConfig(
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      windowsPrinterName: windowsPrinterName ?? this.windowsPrinterName,
      comPort: comPort ?? this.comPort,
      baudRate: baudRate ?? this.baudRate,
    );
  }
}

class PrintingProvider extends ChangeNotifier {
  PrintConfig _config = const PrintConfig();
  PrintService? _printService;
  bool _isPrinting = false;
  String? _lastError;

  PrintConfig get config => _config;
  bool get isPrinting => _isPrinting;
  bool get isConfigured => _config.type != PrinterType.disabled;
  String? get lastError => _lastError;

  void updateConfig(PrintConfig config) {
    _config = config;
    _printService = _createPrintService();
    notifyListeners();
  }

  PrintService? _createPrintService() {
    switch (_config.type) {
      case PrinterType.network:
        if (_config.host.isEmpty) return null;
        return NetworkEscPosPrinter(
          host: _config.host,
          port: _config.port,
        );
      case PrinterType.windows:
        if (_config.windowsPrinterName.isEmpty) return null;
        return WindowsPrintService(
          printerName: _config.windowsPrinterName,
        );
      case PrinterType.serial:
        if (_config.comPort.isEmpty) return null;
        return SerialEscPosPrinter(
          portName: _config.comPort,
          baudRate: _config.baudRate,
        );
      case PrinterType.disabled:
        return null;
    }
  }

  Future<bool> testConnection() async {
    final service = _printService;
    if (service == null) return false;
    return service.testConnection();
  }

  Future<PrintResult> printTicket(TicketPrintData data) async {
    final service = _printService;
    if (service == null) {
      return PrintResult.error('Impresora no configurada');
    }

    _isPrinting = true;
    _lastError = null;
    notifyListeners();

    final result = await service.printTicket(data);

    _isPrinting = false;
    if (!result.success) {
      _lastError = result.errorMessage;
    }
    notifyListeners();

    return result;
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
