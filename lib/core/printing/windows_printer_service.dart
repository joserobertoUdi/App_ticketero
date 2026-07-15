import 'dart:io';

import 'print_service.dart';
import 'ticket_print_data.dart';
import 'esc_pos_commands.dart';

class WindowsPrintService implements PrintService {
  final String printerName;

  WindowsPrintService({this.printerName = ''});

  @override
  Future<bool> testConnection() async {
    if (printerName.isEmpty) return false;
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        _buildTestCommand(),
      ]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  String _buildTestCommand() {
    final name = printerName.replaceAll("'", "''");
    return '''
\$name = '$name';
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class TestPrinter {
    public static bool Test(string name) {
        IntPtr hPrinter;
        bool ok = OpenPrinter(name, out hPrinter, IntPtr.Zero);
        if (ok) ClosePrinter(hPrinter);
        return ok;
    }
    [DllImport("winspool.drv", CharSet=CharSet.Unicode, SetLastError=true)]
    private static extern bool OpenPrinter(string pPrinterName, out IntPtr phPrinter, IntPtr pDefault);
    [DllImport("winspool.drv", SetLastError=true)]
    private static extern bool ClosePrinter(IntPtr hPrinter);
}
"@ -ErrorAction Stop;
if ([TestPrinter]::Test(\$name)) { exit 0 } else { exit 1 }
''';
  }

  @override
  Future<PrintResult> printTicket(TicketPrintData data) async {
    try {
      final bytes = EscPosCommands.buildTicketReceipt(
        headerText: data.header,
        ticketCode: data.ticketCode,
        areaName: data.areaName,
        dateTime: data.dateTime,
        estimatedWait: data.estimatedWait,
        instruction: data.instruction,
        footer: data.footer,
      );

      final allBytes = <int>[];
      for (int i = 0; i < data.copies; i++) {
        allBytes.addAll(bytes);
      }

      return await printRaw(allBytes);
    } catch (e) {
      return PrintResult.error('Error al imprimir: $e');
    }
  }

  @override
  Future<PrintResult> printRaw(List<int> bytes) async {
    if (printerName.isEmpty) {
      return PrintResult.error('Nombre de impresora no configurado');
    }

    try {
      final tempFile = File(
          '${Directory.systemTemp.path}\\ticket_raw_${DateTime.now().millisecondsSinceEpoch}.bin');
      await tempFile.writeAsBytes(bytes);

      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        _buildRawPrintCommand(tempFile.path),
      ]);

      await tempFile.delete();

      if (result.exitCode == 0) {
        return PrintResult.ok;
      }
      final errMsg = result.stderr.toString().trim();
      return PrintResult.error(
          errMsg.isNotEmpty ? errMsg : 'Error desconocido al imprimir');
    } catch (e) {
      return PrintResult.error('Error en impresion raw: $e');
    }
  }

  String _buildRawPrintCommand(String filePath) {
    final psPath = filePath.replaceAll('\\', '\\\\').replaceAll("'", "''");
    final printer = printerName.replaceAll("'", "''");

    return '''
\$printerName = '$printer';
\$bytes = [System.IO.File]::ReadAllBytes('$psPath');
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class RawPrinterHelper {
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    private struct DOC_INFO_1 {
        public string pDocName;
        public string pOutputFile;
        public string pDatatype;
    }
    public static void Print(string printerName, byte[] data) {
        IntPtr hPrinter;
        if (!OpenPrinter(printerName, out hPrinter, IntPtr.Zero))
            throw new System.Exception("ERR:OpenPrinter#" + Marshal.GetLastWin32Error());
        try {
            DOC_INFO_1 docInfo = new DOC_INFO_1();
            docInfo.pDocName = "Ticket";
            docInfo.pDatatype = "RAW";
            if (StartDocPrinter(hPrinter, 1, ref docInfo) == 0)
                throw new System.Exception("ERR:StartDocPrinter#" + Marshal.GetLastWin32Error());
            try {
                if (!StartPagePrinter(hPrinter))
                    throw new System.Exception("ERR:StartPagePrinter#" + Marshal.GetLastWin32Error());
                try {
                    IntPtr pData = Marshal.AllocHGlobal(data.Length);
                    try {
                        Marshal.Copy(data, 0, pData, data.Length);
                        int written;
                        if (!WritePrinter(hPrinter, pData, data.Length, out written))
                            throw new System.Exception("ERR:WritePrinter#" + Marshal.GetLastWin32Error());
                        if (written != data.Length)
                            throw new System.Exception("ERR:WritePrinterWritten#" + written + "#" + data.Length);
                    } finally { Marshal.FreeHGlobal(pData); }
                } finally { EndPagePrinter(hPrinter); }
            } finally { EndDocPrinter(hPrinter); }
        } finally { ClosePrinter(hPrinter); }
    }
    [DllImport("winspool.drv", CharSet=CharSet.Unicode, SetLastError=true)]
    private static extern bool OpenPrinter(string pPrinterName, out IntPtr phPrinter, IntPtr pDefault);
    [DllImport("winspool.drv", SetLastError=true)]
    private static extern bool ClosePrinter(IntPtr hPrinter);
    [DllImport("winspool.drv", CharSet=CharSet.Unicode, SetLastError=true)]
    private static extern int StartDocPrinter(IntPtr hPrinter, int level, ref DOC_INFO_1 docInfo);
    [DllImport("winspool.drv", SetLastError=true)]
    private static extern bool StartPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.drv", SetLastError=true)]
    private static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, int dwCount, out int dwWritten);
    [DllImport("winspool.drv", SetLastError=true)]
    private static extern bool EndPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.drv", SetLastError=true)]
    private static extern bool EndDocPrinter(IntPtr hPrinter);
}
"@ -ErrorAction Stop;
[RawPrinterHelper]::Print(\$printerName, \$bytes);
if (\$?) { exit 0 } else { exit 1 }
''';
  }
}
