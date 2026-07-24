import 'dart:io';

import 'package:dartz/dartz.dart' hide State;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/printing/printing_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/kiosko_fisico_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../../domain/entities/activo_fijo.dart';
import '../../../../domain/entities/kiosko_fisico.dart';
import 'printer_config_panel.dart';

class KioskosAdministracionPanel extends StatefulWidget {
  const KioskosAdministracionPanel({super.key});

  @override
  State<KioskosAdministracionPanel> createState() =>
      _KioskosAdministracionPanelState();
}

class _KioskosAdministracionPanelState
    extends State<KioskosAdministracionPanel> {
  final _sysServerCtrl = TextEditingController();
  final _sysTimeCtrl = TextEditingController();
  final _sysTicketsCtrl = TextEditingController();
  bool _sysTesting = false;
  String? _sysTestResult;

  @override
  void initState() {
    super.initState();
    final sp = context.read<SettingsProvider>();
    _sysServerCtrl.text = sp.serverUrl;
    _sysTimeCtrl.text = sp.tiempoEstimadoMinutos.toString();
    _sysTicketsCtrl.text = sp.maxTicketsPorDia.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KioskoFisicoProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _sysServerCtrl.dispose();
    _sysTimeCtrl.dispose();
    _sysTicketsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<KioskoFisicoProvider, SettingsProvider>(
      builder: (context, provider, settings, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final kioskos = provider.kioskos;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, provider),
              const SizedBox(height: 16),
              if (kioskos.isEmpty)
                const Center(child: Text('No hay kioskos físicos configurados'))
              else
                _buildKioskoGrid(kioskos, provider, settings),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildSystemConfigSection(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, KioskoFisicoProvider provider) {
    return Row(
      children: [
        const Text('Kioskos Físicos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Kiosko'),
          onPressed: () => _showEditDialog(context, null, provider),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refrescar',
          onPressed: () => provider.loadAll(),
        ),
      ],
    );
  }

  Widget _buildKioskoGrid(List<KioskoFisico> kioskos,
      KioskoFisicoProvider provider, SettingsProvider settings) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: kioskos
          .map((k) => _buildKioskoCard(context, k, provider, settings))
          .toList(),
    );
  }

  Widget _buildKioskoCard(BuildContext context, KioskoFisico k,
      KioskoFisicoProvider provider, SettingsProvider settings) {
    return SizedBox(
      width: 380,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_statusIcon(k.activo),
                      color: _statusColor(k.activo), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(k.nombre,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  if (k.esHuerfano)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Pendiente',
                          style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(context, k, provider);
                      } else if (value == 'toggle') {
                        provider.update(k.id, {'activo': !k.activo});
                      } else if (value == 'delete') {
                        _confirmDelete(context, k, provider);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(
                          value: 'toggle',
                          child: Text(k.activo ? 'Desactivar' : 'Activar')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
              const Divider(),
              _infoRow(Icons.location_on, 'Ubicación', k.ubicacion),
              if (k.logoUrl != null && k.logoUrl!.isNotEmpty)
                _infoRow(Icons.image, 'Logo', k.logoUrl!),
              if (k.videoUrl != null && k.videoUrl!.isNotEmpty)
                _infoRow(Icons.videocam, 'Video', k.videoUrl!),
              if (k.areaIds.isNotEmpty)
                _infoRow(Icons.category, 'Áreas', '${k.areaIds.length} asignadas'),
              if (k.ipKiosko != null)
                _infoRow(Icons.router, 'IP Kiosko', k.ipKiosko!),
              if (k.nombreImpresora != null)
                _infoRow(Icons.print, 'Impresora', k.nombreImpresora!),
              if (k.activosFijos.isNotEmpty)
                _infoRow(Icons.inventory, 'Activos', '${k.activosFijos.length} registrados'),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(bool activo) =>
      activo ? Icons.check_circle : Icons.cancel;

  Color _statusColor(bool activo) => activo ? Colors.green : Colors.red;

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, KioskoFisico k, KioskoFisicoProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Kiosko'),
        content: Text('¿Desactivar kiosko "${k.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              provider.delete(k.id);
              Navigator.pop(ctx);
            },
            child:
                const Text('Desactivar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, KioskoFisico? existing,
      KioskoFisicoProvider provider) {
    final nameCtrl =
        TextEditingController(text: existing?.nombre ?? '');
    final ubicCtrl =
        TextEditingController(text: existing?.ubicacion ?? '');
    final ipEqCtrl =
        TextEditingController(text: existing?.ipEquipo ?? '');
    final ipKioskoCtrl =
        TextEditingController(text: existing?.ipKiosko ?? '');
    final mascaraEqCtrl =
        TextEditingController(text: existing?.mascaraRedEquipo ?? '');
    final gatewayEqCtrl =
        TextEditingController(text: existing?.gatewayEquipo ?? '');
    final dnsEqCtrl =
        TextEditingController(text: existing?.dnsEquipo ?? '');
    final ipRedCtrl =
        TextEditingController(text: existing?.direccionIP ?? '');
    final mascaraRedCtrl =
        TextEditingController(text: existing?.mascaraSubred ?? '');
    final gatewayRedCtrl =
        TextEditingController(text: existing?.gatewayRed ?? '');
    final dnsPrimarioCtrl =
        TextEditingController(text: existing?.dnsPrimario ?? '');
    final dnsSecundarioCtrl =
        TextEditingController(text: existing?.dnsSecundario ?? '');
    final anchoPapelCtrl =
        TextEditingController(text: (existing?.anchoPapelMM ?? 80).toString());
    final copiasCtrl =
        TextEditingController(text: (existing?.copias ?? 1).toString());
    final logoUrlCtrl =
        TextEditingController(text: existing?.logoUrl ?? '');
    final videoUrlCtrl =
        TextEditingController(text: existing?.videoUrl ?? '');

    int? selectedUbicacionId = existing?.ubicacionId;
    bool dhcp = existing?.dhcp ?? true;
    bool impresionAutomatica = existing?.impresionAutomatica ?? true;
    bool activo = existing?.activo ?? true;
    String tipoConexionRed = existing?.tipoConexionRed ?? 'WiFi';

    List<int> selectedAreaIds =
        existing?.areaIds.isNotEmpty == true ? List.from(existing!.areaIds) : [];
    List<ActivoFijo> activosFijos =
        existing?.activosFijos.isNotEmpty == true
            ? List.from(existing!.activosFijos)
            : [];

    final printing = context.read<PrintingProvider>();
    if (existing != null) {
      PrinterType pt;
      switch (existing.tipoConexionImpresora) {
        case 'RED':
          pt = PrinterType.network;
          break;
        case 'USB':
          pt = PrinterType.windows;
          break;
        case 'SERIAL':
          pt = PrinterType.serial;
          break;
        default:
          pt = PrinterType.disabled;
      }
      printing.updateConfig(PrintConfig(
        type: pt,
        host: existing.ipImpresora ?? '',
        port: int.tryParse(existing.puertoImpresora ?? '') ?? 9100,
        windowsPrinterName: pt == PrinterType.windows ? (existing.nombreImpresora ?? '') : '',
        comPort: pt == PrinterType.serial ? (existing.puertoImpresora ?? '') : '',
        baudRate: pt == PrinterType.serial ? (int.tryParse(existing.ipImpresora ?? '') ?? 19200) : 19200,
      ));
    } else {
      printing.updateConfig(const PrintConfig(type: PrinterType.disabled));
    }

    Map<String, String?> localErrors = {};

    String? _validateField(String fieldName, String? value,
        {bool required = false, int? maxLength}) {
      if (required && (value == null || value.trim().isEmpty)) {
        return 'Este campo es obligatorio';
      }
      if (maxLength != null && value != null && value.length > maxLength) {
        return 'Máximo $maxLength caracteres';
      }
      return null;
    }

    bool _validateAll(Map<String, String?> errors,
        {required String nombre, required String ubicacion, required List<int> areaIds}) {
      errors.clear();
      errors['nombre'] = _validateField('nombre', nombre, required: true, maxLength: 100);
      errors['ubicacion'] = _validateField('ubicacion', ubicacion, required: true, maxLength: 150);
      if (areaIds.isEmpty) {
        errors['areaIds'] = 'Debe seleccionar al menos un área';
      }
      errors.removeWhere((_, v) => v == null);
      return errors.isEmpty;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: SizedBox(
            width: 700,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Icon(existing != null ? Icons.edit : Icons.add,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                          existing != null
                              ? 'Editar Kiosko'
                              : 'Nuevo Kiosko',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(Icons.info, 'Información Básica'),
                        const SizedBox(height: 12),
                        TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                                labelText: 'Nombre',
                                border: const OutlineInputBorder(),
                                errorText: localErrors['nombre']),
                            onChanged: (_) {
                              if (localErrors['nombre'] != null) {
                                setDialogState(() {
                                  localErrors.remove('nombre');
                                });
                              }
                            }),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                  controller: ubicCtrl,
                                  decoration: InputDecoration(
                                      labelText: 'Ubicación física',
                                      border: const OutlineInputBorder(),
                                      errorText: localErrors['ubicacion']),
                                  onChanged: (_) {
                                    if (localErrors['ubicacion'] != null) {
                                      setDialogState(() {
                                        localErrors.remove('ubicacion');
                                      });
                                    }
                                  }),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: activo,
                              onChanged: (v) =>
                                  setDialogState(() => activo = v),
                            ),
                            const Text('Activo'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                            controller: logoUrlCtrl,
                            decoration: const InputDecoration(
                                labelText: 'URL del Logo',
                                hintText: 'https://ejemplo.com/logo.png',
                                border: OutlineInputBorder())),
                        const SizedBox(height: 8),
                        TextField(
                            controller: videoUrlCtrl,
                            decoration: const InputDecoration(
                                labelText: 'URL del Video',
                                hintText: 'https://ejemplo.com/video.mp4',
                                border: OutlineInputBorder())),
                        const SizedBox(height: 16),
                        _sectionHeader(Icons.category, 'Asignación de Áreas'),
                        const SizedBox(height: 8),
                        Consumer<AreaProvider>(
                          builder: (ctx, areaProv, _) {
                            if (areaProv.areas.isEmpty) {
                              return const Text('No hay áreas disponibles');
                            }
                            return Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: areaProv.areas.map((a) {
                                final sel = selectedAreaIds.contains(a.id);
                                return FilterChip(
                                  label: Text(a.nombre),
                                  selected: sel,
                                  onSelected: (v) {
                                    setDialogState(() {
                                      if (v) {
                                        selectedAreaIds.add(a.id);
                                      } else {
                                        selectedAreaIds.remove(a.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                              );
                            },
                          ),
                        if (localErrors['areaIds'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(localErrors['areaIds']!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12)),
                          ),
                        const SizedBox(height: 16),
                        _sectionHeader(
                            Icons.print, 'Configuración de Impresora'),
                        const SizedBox(height: 8),
                        Consumer<PrintingProvider>(
                          builder: (ctx, printing, _) {
                            final c = printing.config;
                            String resumen;
                            switch (c.type) {
                              case PrinterType.network:
                                resumen = 'Red (TCP/IP) · ${c.host}:${c.port}';
                                break;
                              case PrinterType.windows:
                                resumen = 'Windows · ${c.windowsPrinterName}';
                                break;
                              case PrinterType.serial:
                                resumen = 'Serial · ${c.comPort} @ ${c.baudRate} baud';
                                break;
                              case PrinterType.disabled:
                                resumen = 'Desactivada';
                                break;
                            }
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(resumen,
                                              style: const TextStyle(fontSize: 14)),
                                          if (c.type == PrinterType.disabled)
                                            const Text('La impresora no está configurada',
                                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.tune, size: 18),
                                      label: const Text('Configurar'),
                                      onPressed: () {
                                        showDialog(
                                          context: ctx,
                                          builder: (_) => const Dialog(
                                            insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                                            child: SizedBox(
                                              width: 600,
                                              child: PrinterConfigPanel(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: TextField(
                                  controller: anchoPapelCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Ancho mm',
                                      border: OutlineInputBorder(),
                                      isDense: true),
                                  keyboardType: TextInputType.number),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                  controller: copiasCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Copias',
                                      border: OutlineInputBorder(),
                                      isDense: true),
                                  keyboardType: TextInputType.number),
                            ),
                            const SizedBox(width: 8),
                            const Text('Auto'),
                            Switch(
                              value: impresionAutomatica,
                              onChanged: (v) => setDialogState(
                                  () => impresionAutomatica = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionHeader(Icons.router, 'Configuración de Red'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                  controller: ipKioskoCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'IP Kiosko (auto)',
                                      border: OutlineInputBorder())),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.wifi_find, size: 18),
                              label: const Text('Detectar'),
                              onPressed: () async {
                                final ip =
                                    await provider.detectarIp();
                                if (ip != null && mounted) {
                                  setDialogState(
                                      () => ipKioskoCtrl.text = ip);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                            controller: ipEqCtrl,
                            decoration: const InputDecoration(
                                labelText: 'IP Equipo',
                                border: OutlineInputBorder())),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                  controller: mascaraEqCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Máscara Equipo',
                                      border: OutlineInputBorder())),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                  controller: gatewayEqCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Gateway Equipo',
                                      border: OutlineInputBorder())),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                  controller: dnsEqCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'DNS Equipo',
                                      border: OutlineInputBorder())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Red del Kiosko',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: tipoConexionRed,
                                decoration: const InputDecoration(
                                    labelText: 'Tipo',
                                    border: OutlineInputBorder(),
                                    isDense: true),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'WiFi', child: Text('WiFi')),
                                  DropdownMenuItem(
                                      value: 'Ethernet',
                                      child: Text('Ethernet')),
                                ],
                                onChanged: (v) => setDialogState(
                                    () => tipoConexionRed = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('DHCP'),
                            Switch(
                              value: dhcp,
                              onChanged: (v) =>
                                  setDialogState(() => dhcp = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                  controller: ipRedCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'IP Kiosko (red)',
                                      border: OutlineInputBorder())),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                  controller: mascaraRedCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Máscara',
                                      border: OutlineInputBorder())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                  controller: gatewayRedCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Gateway',
                                      border: OutlineInputBorder())),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                  controller: dnsPrimarioCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'DNS Primario',
                                      border: OutlineInputBorder())),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                  controller: dnsSecundarioCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'DNS Secundario',
                                      border: OutlineInputBorder())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionHeader(
                            Icons.inventory, 'Inventario de Activos'),
                        const SizedBox(height: 8),
                        ...List.generate(activosFijos.length, (i) {
                          final a = activosFijos[i];
                          final tipoCtrl = TextEditingController(text: a.tipoActivo);
                          final numCtrl = TextEditingController(text: a.numeroActivo);
                          final descCtrl = TextEditingController(text: a.descripcion ?? '');
                          final marcaCtrl = TextEditingController(text: a.marca ?? '');
                          final modeloCtrl = TextEditingController(text: a.modelo ?? '');
                          final serieCtrl = TextEditingController(text: a.serie ?? '');
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Activo #${i + 1}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 18, color: Colors.red),
                                        onPressed: () => setDialogState(
                                            () => activosFijos.removeAt(i)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                              labelText: 'Tipo',
                                              border: OutlineInputBorder(),
                                              isDense: true),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isDense: true,
                                              isExpanded: true,
                                              value: () {
                                                final valorActual = tipoCtrl.text.isNotEmpty ? tipoCtrl.text : 'CPU';
                                                final opcionesValidas = ['CPU', 'Monitor', 'Impresora', 'Tablet', 'Router', 'UPS', 'PC', 'Otro'];
                                                return opcionesValidas.contains(valorActual) ? valorActual : 'Otro';
                                              }(),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 'CPU',
                                                    child: Text('CPU')),
                                                DropdownMenuItem(
                                                    value: 'Monitor',
                                                    child: Text('Monitor')),
                                                DropdownMenuItem(
                                                    value: 'Impresora',
                                                    child: Text('Impresora')),
                                                DropdownMenuItem(
                                                    value: 'Tablet',
                                                    child: Text('Tablet')),
                                                DropdownMenuItem(
                                                    value: 'Router',
                                                    child: Text('Router')),
                                                DropdownMenuItem(
                                                    value: 'UPS',
                                                    child: Text('UPS')),
                                                DropdownMenuItem(
                                                    value: 'PC',
                                                    child: Text('PC')),
                                                DropdownMenuItem(
                                                    value: 'Otro',
                                                    child: Text('Otro')),
                                              ],
                                              onChanged: (v) {
                                                if (v == null) return;
                                                setDialogState(() {
                                                  tipoCtrl.text = v;
                                                  activosFijos[i] = a.copyWith(
                                                      tipoActivo: v);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                            controller: numCtrl,
                                            decoration: const InputDecoration(
                                                labelText: 'N° Activo',
                                                border: OutlineInputBorder(),
                                                isDense: true),
                                            onChanged: (v) {
                                              activosFijos[i] = a.copyWith(
                                                  numeroActivo: v);
                                            }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                            controller: marcaCtrl,
                                            decoration: const InputDecoration(
                                                labelText: 'Marca',
                                                border: OutlineInputBorder(),
                                                isDense: true),
                                            onChanged: (v) {
                                              activosFijos[i] = a.copyWith(
                                                  marca: v);
                                            }),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                            controller: modeloCtrl,
                                            decoration: const InputDecoration(
                                                labelText: 'Modelo',
                                                border: OutlineInputBorder(),
                                                isDense: true),
                                            onChanged: (v) {
                                              activosFijos[i] = a.copyWith(
                                                  modelo: v);
                                            }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                            controller: serieCtrl,
                                            decoration: const InputDecoration(
                                                labelText: 'Serie',
                                                border: OutlineInputBorder(),
                                                isDense: true),
                                            onChanged: (v) {
                                              activosFijos[i] = a.copyWith(
                                                  serie: v);
                                            }),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                            controller: descCtrl,
                                            decoration: const InputDecoration(
                                                labelText: 'Descripción',
                                                border: OutlineInputBorder(),
                                                isDense: true),
                                            onChanged: (v) {
                                              activosFijos[i] = a.copyWith(
                                                  descripcion: v);
                                            }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar activo'),
                          onPressed: () => setDialogState(() {
                            final nextNum = activosFijos.length + 1;
                            activosFijos.add(ActivoFijo(
                                tipoActivo: 'CPU',
                                numeroActivo: nextNum.toString().padLeft(3, '0')));
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          localErrors = {};
                          if (!_validateAll(localErrors,
                              nombre: nameCtrl.text,
                              ubicacion: ubicCtrl.text,
                              areaIds: selectedAreaIds)) {
                            setDialogState(() {});
                            return;
                          }

                          final printing = context.read<PrintingProvider>();
                          final pc = printing.config;
                          String? tipoConexionImp;
                          String? nombreImp;
                          String? ipImp;
                          String? puertoImp;
                          switch (pc.type) {
                            case PrinterType.network:
                              tipoConexionImp = 'RED';
                              ipImp = pc.host.isNotEmpty ? pc.host : null;
                              puertoImp = pc.port.toString();
                              break;
                            case PrinterType.windows:
                              tipoConexionImp = 'USB';
                              nombreImp = pc.windowsPrinterName.isNotEmpty ? pc.windowsPrinterName : null;
                              break;
                            case PrinterType.serial:
                              tipoConexionImp = 'SERIAL';
                              puertoImp = pc.comPort.isNotEmpty ? pc.comPort : null;
                              ipImp = pc.baudRate.toString();
                              break;
                            case PrinterType.disabled:
                              tipoConexionImp = 'DESACTIVADO';
                              break;
                          }

                          final data = <String, dynamic>{
                            'nombre': nameCtrl.text,
                            'ubicacion': ubicCtrl.text,
                            'ubicacionId': selectedUbicacionId ?? 1,
                            'areaIds': selectedAreaIds,
                            'activo': activo,
                            'ipKiosko': ipKioskoCtrl.text.isNotEmpty
                                ? ipKioskoCtrl.text
                                : null,
                            'nombreImpresora': nombreImp,
                            'puertoImpresora': puertoImp,
                            'ipImpresora': ipImp,
                            'tipoConexionImpresora': tipoConexionImp,
                            'anchoPapelMM':
                                int.tryParse(anchoPapelCtrl.text) ?? 80,
                            'copias': int.tryParse(copiasCtrl.text) ?? 1,
                            'impresionAutomatica': impresionAutomatica,
                            'ipEquipo': ipEqCtrl.text.isNotEmpty
                                ? ipEqCtrl.text
                                : null,
                            'mascaraRedEquipo': mascaraEqCtrl.text.isNotEmpty
                                ? mascaraEqCtrl.text
                                : null,
                            'gatewayEquipo': gatewayEqCtrl.text.isNotEmpty
                                ? gatewayEqCtrl.text
                                : null,
                            'dnsEquipo': dnsEqCtrl.text.isNotEmpty
                                ? dnsEqCtrl.text
                                : null,
                            'tipoConexionRed': tipoConexionRed,
                            'dhcp': dhcp,
                            'direccionIP': ipRedCtrl.text.isNotEmpty
                                ? ipRedCtrl.text
                                : null,
                            'mascaraSubred': mascaraRedCtrl.text.isNotEmpty
                                ? mascaraRedCtrl.text
                                : null,
                            'gatewayRed': gatewayRedCtrl.text.isNotEmpty
                                ? gatewayRedCtrl.text
                                : null,
                            'dnsPrimario': dnsPrimarioCtrl.text.isNotEmpty
                                ? dnsPrimarioCtrl.text
                                : null,
                            'dnsSecundario': dnsSecundarioCtrl.text.isNotEmpty
                                ? dnsSecundarioCtrl.text
                                : null,
                            'logoUrl': logoUrlCtrl.text.isNotEmpty
                                ? logoUrlCtrl.text
                                : null,
                            'videoUrl': videoUrlCtrl.text.isNotEmpty
                                ? videoUrlCtrl.text
                                : null,
                            'activosFijos': activosFijos
                                .map((a) => a.toJson())
                                .toList(),
                          };

                          Either<Failure, KioskoFisico> result;
                          if (existing != null) {
                            result = await provider.update(existing.id, data);
                          } else {
                            result = await provider.create(data);
                          }

                          if (ctx.mounted) {
                            result.fold(
                              (failure) {
                                if (failure is ValidationFailure &&
                                    failure.errors != null) {
                                  final serverErrors = <String, String?>{};
                                  failure.errors!.forEach((key, msgs) {
                                    serverErrors[key] = msgs.join('\n');
                                  });
                                  setDialogState(() {
                                    localErrors.addAll(serverErrors);
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(failure.message),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              },
                              (_) => Navigator.pop(ctx),
                            );
                          }
                        },
                        child: Text(existing != null ? 'Guardar' : 'Crear'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSystemConfigSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Configuración General del Sistema',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeaderSmall(Icons.dns, 'Conexión al Servidor'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _sysServerCtrl,
                          decoration: const InputDecoration(
                            labelText: 'URL del servidor API',
                            hintText: 'http://localhost:5000',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _sysTesting
                                    ? null
                                    : _testServerConnection,
                                icon: _sysTesting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(
                                        Icons.wifi_tethering, size: 18),
                                label: Text(_sysTesting
                                    ? 'Probando...'
                                    : 'Probar conexión'),
                              ),
                            ),
                            if (_sysTestResult != null) ...[
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(_sysTestResult!,
                                    style: TextStyle(
                                      color: _sysTestResult!.contains('✓')
                                          ? AppColors.success
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    )),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeaderSmall(
                            Icons.support_agent, 'Atención al Cliente'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _sysTimeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Tiempo estimado de espera',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  suffixText: 'min',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _sysTicketsCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Máximo tickets por día',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeaderSmall(
                            Icons.info_outline, 'Información'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Versión de la aplicación: ',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                            const Text('1.0.0',
                                style:
                                    TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _saveSystemConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar configuración',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeaderSmall(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _sysTesting = true;
      _sysTestResult = null;
    });
    try {
      final dio = Dio();
      final response = await dio
          .get('${_sysServerCtrl.text}/healthz')
          .timeout(const Duration(seconds: 5));
      setState(() {
        _sysTestResult = response.statusCode == 200
            ? 'Conexión exitosa ✓'
            : 'Respuesta inesperada (${response.statusCode})';
      });
    } on DioException catch (e) {
      setState(() {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _sysTestResult = 'Tiempo de espera agotado';
        } else if (e.error is SocketException) {
          _sysTestResult = 'No se pudo conectar al servidor';
        } else {
          _sysTestResult = 'Error de conexión';
        }
      });
    } catch (e) {
      setState(() {
        _sysTestResult = 'Error: $e';
      });
    } finally {
      setState(() => _sysTesting = false);
    }
  }

  void _saveSystemConfig() {
    final sp = context.read<SettingsProvider>();
    sp.updateServerUrl(_sysServerCtrl.text);
    final t = int.tryParse(_sysTimeCtrl.text);
    final tk = int.tryParse(_sysTicketsCtrl.text);
    if (t != null) sp.updateTimeEstimate(t);
    if (tk != null) sp.updateMaxTickets(tk);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
