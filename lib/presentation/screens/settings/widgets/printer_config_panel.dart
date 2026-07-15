import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/printing/printing_provider.dart';
import '../../../../core/printing/serial_escpos_printer.dart';

class PrinterConfigPanel extends StatefulWidget {
  const PrinterConfigPanel({super.key});

  @override
  State<PrinterConfigPanel> createState() => _PrinterConfigPanelState();
}

class _PrinterConfigPanelState extends State<PrinterConfigPanel> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '9100');
  final _printerNameController = TextEditingController();
  final _comPortController = TextEditingController();
  final _baudRateController = TextEditingController(text: '19200');
  bool _testing = false;
  String? _testResult;
  List<String> _availablePorts = [];

  @override
  void initState() {
    super.initState();
    final config =
        Provider.of<PrintingProvider>(context, listen: false).config;
    _hostController.text = config.host;
    _portController.text = config.port.toString();
    _printerNameController.text = config.windowsPrinterName;
    _comPortController.text = config.comPort;
    _baudRateController.text = config.baudRate.toString();
    _refreshPorts();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _printerNameController.dispose();
    _comPortController.dispose();
    _baudRateController.dispose();
    super.dispose();
  }

  Future<void> _refreshPorts() async {
    final ports = await SerialEscPosPrinter.listAvailablePorts();
    if (mounted) {
      setState(() => _availablePorts = ports);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Consumer<PrintingProvider>(
        builder: (context, printing, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configuracion de Impresora',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'Configure la impresora termica MP-4200 TH para imprimir tickets.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Tipo de impresora
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipo de conexion',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        SegmentedButton<PrinterType>(
                          segments: const [
                            ButtonSegment(
                              value: PrinterType.disabled,
                              label: Text('Desactivada'),
                              icon: Icon(Icons.print_disabled),
                            ),
                            ButtonSegment(
                              value: PrinterType.network,
                              label: Text('Red (TCP/IP)'),
                              icon: Icon(Icons.wifi),
                            ),
                            ButtonSegment(
                              value: PrinterType.windows,
                              label: Text('Windows'),
                              icon: Icon(Icons.desktop_windows),
                            ),
                            ButtonSegment(
                              value: PrinterType.serial,
                              label: Text('COM (Serial)'),
                              icon: Icon(Icons.cable),
                            ),
                          ],
                          selected: {printing.config.type},
                          onSelectionChanged: (selected) {
                            final newType = selected.first;
                            printing.updateConfig(
                                printing.config.copyWith(type: newType));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Config especifica segun tipo
                if (printing.config.type == PrinterType.network)
                  _buildNetworkConfig(printing),
                if (printing.config.type == PrinterType.windows)
                  _buildWindowsConfig(printing),
                if (printing.config.type == PrinterType.serial)
                  _buildSerialConfig(printing),

                if (printing.config.type != PrinterType.disabled) ...[
                  const SizedBox(height: 16),
                  _buildTestButton(printing),
                ],

                if (_testResult != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: _testResult == 'OK'
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _testResult == 'OK'
                                ? Icons.check_circle
                                : Icons.error,
                            color: _testResult == 'OK'
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _testResult == 'OK'
                                  ? 'Conexion exitosa con la impresora'
                                  : 'Error: $_testResult',
                              style: TextStyle(
                                color: _testResult == 'OK'
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (printing.isPrinting) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],

                if (printing.lastError != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              printing.lastError!,
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => printing.clearError(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkConfig(PrintingProvider printing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuracion de Red',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Para impresoras conectadas via Ethernet (puerto 9100 por defecto)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Direccion IP',
                      hintText: '192.168.1.200',
                      prefixIcon: Icon(Icons.computer),
                    ),
                    onChanged: (value) {
                      printing.updateConfig(
                          printing.config.copyWith(host: value));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Puerto',
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final port = int.tryParse(value) ?? 9100;
                      printing.updateConfig(
                          printing.config.copyWith(port: port));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowsConfig(PrintingProvider printing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuracion Windows',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Para impresoras instaladas como dispositivo Windows.\n'
              'Deje el nombre vacio para usar la impresora predeterminada.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _printerNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la impresora',
                hintText: 'MP-4200 TH (dejar vacio para predeterminada)',
                prefixIcon: Icon(Icons.print),
              ),
              onChanged: (value) {
                printing.updateConfig(
                    printing.config.copyWith(windowsPrinterName: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSerialConfig(PrintingProvider printing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuracion Serial (COM)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Para impresoras conectadas via puerto serie (RS-232 / COM).\n'
              'Baud rate tipico: 19200 o 9600.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: printing.config.comPort.isNotEmpty
                        ? printing.config.comPort
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Puerto COM',
                      prefixIcon: Icon(Icons.usb),
                    ),
                    items: [
                      if (_availablePorts.isEmpty) ...[
                        const DropdownMenuItem(
                          value: null,
                          child: Text('(ninguno detectado)'),
                        ),
                      ],
                      ..._availablePorts.map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p),
                          )),
                      const DropdownMenuItem(
                        value: 'COM1',
                        child: Text('COM1'),
                      ),
                      const DropdownMenuItem(
                        value: 'COM2',
                        child: Text('COM2'),
                      ),
                      const DropdownMenuItem(
                        value: 'COM3',
                        child: Text('COM3'),
                      ),
                      const DropdownMenuItem(
                        value: 'COM4',
                        child: Text('COM4'),
                      ),
                      const DropdownMenuItem(
                        value: 'COM5',
                        child: Text('COM5'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        printing.updateConfig(
                            printing.config.copyWith(comPort: value));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Detectar puertos',
                  onPressed: _refreshPorts,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _baudRateController,
                    decoration: const InputDecoration(
                      labelText: 'Baud rate',
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final baud = int.tryParse(value) ?? 19200;
                      printing.updateConfig(
                          printing.config.copyWith(baudRate: baud));
                    },
                  ),
                ),
              ],
            ),
            if (_availablePorts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No se detectaron puertos COM. Verifique la conexion e intente "Detectar puertos".',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(PrintingProvider printing) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _testing ? null : _testPrinter,
        icon: _testing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.wifi_tethering),
        label: Text(_testing ? 'Probando...' : 'Probar conexion'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Future<void> _testPrinter() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final printing = Provider.of<PrintingProvider>(context, listen: false);
    final ok = await printing.testConnection();

    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = ok ? 'OK' : 'No se pudo conectar a la impresora';
      });
    }
  }
}
