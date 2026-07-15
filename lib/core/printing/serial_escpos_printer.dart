import 'dart:io';

import 'print_service.dart';
import 'ticket_print_data.dart';
import 'esc_pos_commands.dart';

class SerialEscPosPrinter implements PrintService {
  final String portName;
  final int baudRate;

  SerialEscPosPrinter({
    required this.portName,
    this.baudRate = 19200,
  });

  @override
  Future<bool> testConnection() async {
    final script = _buildScript('test');
    final result = await _runPowerShell(script);
    return result.exitCode == 0 && result.stdout.trim() == 'OK';
  }

  @override
  Future<PrintResult> printTicket(TicketPrintData data) async {
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

    final result = await printRaw(bytes);
    return result;
  }

  @override
  Future<PrintResult> printRaw(List<int> bytes) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}\\ticket_${DateTime.now().millisecondsSinceEpoch}.bin',
      );
      await tempFile.writeAsBytes(bytes);

      final script = _buildScript('print', tempFile.path);
      final result = await _runPowerShell(script);

      try {
        await tempFile.delete();
      } catch (_) {}

      if (result.exitCode != 0) {
        return PrintResult.error(
          result.stderr.isNotEmpty ? result.stderr : 'Error al enviar a COM',
        );
      }

      return PrintResult.ok;
    } catch (e) {
      return PrintResult.error('Error en impresion serial: $e');
    }
  }

  String _buildScript(String action, [String? filePath]) {
    final port = portName;
    final baud = baudRate;

    switch (action) {
      case 'test':
        return '''
try {
  \$psPort = New-Object System.IO.Ports.SerialPort "$port", $baud, None, 8, One
  \$psPort.Open()
  \$psPort.Close()
  Write-Host "OK"
} catch {
  Write-Host "ERROR: \$_"
  exit 1
}
''';
      case 'print':
        final binPath = filePath!.replaceAll('\\', '\\\\');
        return '''
try {
  \$bytes = [byte[]](Get-Content -Path "$binPath" -Encoding Byte -Raw)
  \$psPort = New-Object System.IO.Ports.SerialPort "$port", $baud, None, 8, One
  \$psPort.Open()
  \$psPort.Write(\$bytes, 0, \$bytes.Length)
  \$psPort.Close()
} catch {
  Write-Host "ERROR: \$_"
  exit 1
}
''';
      default:
        return '';
    }
  }

  Future<ProcessResult> _runPowerShell(String script) async {
    return Process.run(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
      runInShell: true,
    );
  }

  static Future<List<String>> listAvailablePorts() async {
    final result = await Process.run(
      'powershell',
      [
        '-NoProfile',
        '-Command',
        '[System.IO.Ports.SerialPort]::GetPortNames()',
      ],
      runInShell: true,
    );
    if (result.exitCode != 0) return [];
    return result.stdout
        .toString()
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
