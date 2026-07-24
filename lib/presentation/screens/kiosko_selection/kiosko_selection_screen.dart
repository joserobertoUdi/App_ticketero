import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/printing/printing_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/area_logo_presets.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/time_sync_service.dart';
import '../../../domain/entities/kiosko_fisico.dart';
import '../../providers/area_provider.dart';
import '../../providers/kiosko_fisico_provider.dart';
import '../../providers/settings_provider.dart';

class KioskoSelectionScreen extends StatefulWidget {
  const KioskoSelectionScreen({super.key});

  @override
  State<KioskoSelectionScreen> createState() => _KioskoSelectionScreenState();
}

class _KioskoSelectionScreenState extends State<KioskoSelectionScreen> {
  bool _autoRegistering = false;
  bool _syncingTime = true;
  String? _autoError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initTimeSync();
      _tryAutoRegister();
    });
  }

  Future<void> _initTimeSync() async {
    final timeSync = TimeSyncService();
    await timeSync.initialize();
    if (mounted) setState(() => _syncingTime = false);
  }

  Future<void> _tryAutoRegister() async {
    final settings = context.read<SettingsProvider>();

    if (settings.hasKioskoSelected) {
      final kf = context.read<KioskoFisicoProvider>();
      await kf.loadAll();
      final existing = kf.kioskos.where((k) => k.id == settings.selectedKioskoId).firstOrNull;
      if (existing != null) {
        await settings.setSelectedKioskoId(existing.id, areaIds: existing.areaIds, logoUrl: existing.logoUrl, videoUrl: existing.videoUrl, nombre: existing.nombre);
        await _loadPrinterConfig(existing.id);
        if (mounted) Navigator.pushReplacementNamed(context, '/ticket');
        return;
      }
      await settings.setSelectedKioskoId(null);
    }

    setState(() => _autoRegistering = true);
    try {
      final providers = <String, String?>{
        'ipEquipo': null,
        'mascaraRedEquipo': null,
        'gatewayEquipo': null,
        'dnsEquipo': null,
      };
      try {
        final interfaces = await NetworkInterface.list();
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              providers['ipEquipo'] = addr.address;
              break;
            }
          }
          if (providers['ipEquipo'] != null) break;
        }
      } catch (_) {}

      try {
        final result = await Process.run('powershell', [
          '-Command',
          'Get-NetIPAddress -AddressFamily IPv4 | Where-Object { \$_.InterfaceAlias -ne "Loopback" } | '
              'Select-Object IPAddress,PrefixLength,InterfaceIndex | ConvertTo-Json'
        ]);
        if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
          final decoded = jsonDecode(result.stdout.toString());
          final list = decoded is List ? decoded : [decoded];
          if (providers['ipEquipo'] == null && list.isNotEmpty) {
            providers['ipEquipo'] = list[0]['IPAddress']?.toString();
          }
          if (list.isNotEmpty && providers['ipEquipo'] != null) {
            final prefix = list[0]['PrefixLength'];
            if (prefix != null) {
              final cidr = int.tryParse(prefix.toString());
              if (cidr != null) {
                if (cidr == 24) providers['mascaraRedEquipo'] = '255.255.255.0';
                else if (cidr == 16) providers['mascaraRedEquipo'] = '255.255.0.0';
                else if (cidr == 8) providers['mascaraRedEquipo'] = '255.0.0.0';
              }
            }
          }
        }
      } catch (_) {}

      if (providers['gatewayEquipo'] == null) {
        try {
          final gw = await Process.run('powershell', [
            '-Command',
            '(Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1).NextHop'
          ]);
          if (gw.exitCode == 0) {
            final gwStr = gw.stdout.toString().trim();
            if (gwStr.isNotEmpty) providers['gatewayEquipo'] = gwStr;
          }
        } catch (_) {}
      }

      if (providers['dnsEquipo'] == null) {
        try {
          final dns = await Process.run('powershell', [
            '-Command',
            '(Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -First 1).ServerAddresses -join ","'
          ]);
          if (dns.exitCode == 0) {
            final dnsStr = dns.stdout.toString().trim();
            if (dnsStr.isNotEmpty) providers['dnsEquipo'] = dnsStr;
          }
        } catch (_) {}
      }

      final kf = context.read<KioskoFisicoProvider>();
      final kiosko = await kf.autoRegistrar(providers);
      if (kiosko != null && mounted) {
        await settings.setSelectedKioskoId(kiosko.id, areaIds: kiosko.areaIds, logoUrl: kiosko.logoUrl, videoUrl: kiosko.videoUrl, nombre: kiosko.nombre);
        await _loadPrinterConfig(kiosko.id);
        if (mounted) Navigator.pushReplacementNamed(context, '/ticket');
        return;
      }
    } catch (e) {
      if (mounted) setState(() => _autoError = 'Error al detectar kiosko: $e');
    }
    if (mounted) {
      setState(() => _autoRegistering = false);
      context.read<KioskoFisicoProvider>().loadAll();
    }
  }

  Future<void> _loadPrinterConfig(int kioskoId) async {
    final printerData = await context.read<KioskoFisicoProvider>().getPrinterConfig(kioskoId);
    if (printerData == null) return;
    final tipoConexion = printerData['tipoConexion'] as String? ?? '';
    final ip = printerData['direccionIP'] as String? ?? '';
    final puerto = printerData['puerto'] as String? ?? '';
    final nombreImp = printerData['nombreImpresora'] as String? ?? '';
    PrinterType pt;
    switch (tipoConexion) {
      case 'RED': pt = PrinterType.network; break;
      case 'USB': pt = PrinterType.windows; break;
      case 'SERIAL': pt = PrinterType.serial; break;
      default: pt = PrinterType.disabled;
    }
    context.read<PrintingProvider>().updateConfig(PrintConfig(
      type: pt,
      host: pt == PrinterType.network ? ip : '',
      port: pt == PrinterType.network ? (int.tryParse(puerto) ?? 9100) : 9100,
      windowsPrinterName: pt == PrinterType.windows ? nombreImp : '',
      comPort: pt == PrinterType.serial ? puerto : '',
      baudRate: pt == PrinterType.serial ? (int.tryParse(ip) ?? 19200) : 19200,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Consumer3<KioskoFisicoProvider, SettingsProvider, AreaProvider>(
              builder: (context, kfProvider, settings, areaProvider, _) {
                if (_syncingTime) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Sincronizando hora con el servidor...',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    ],
                  );
                }
                if (_autoRegistering || kfProvider.isLoading) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_autoError ?? 'Detectando kiosko...',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    ],
                  );
                }

                final kioskos = kfProvider.kioskos;
                if (kioskos.isEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text('No hay kioskos físicos disponibles',
                          style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/ticket'),
                        child: const Text('Continuar sin selección'),
                      ),
                    ],
                  );
                }
                final timeSync = context.read<TimeSyncService>();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (timeSync.isSynced && !timeSync.isDriftAcceptable)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 20, color: Colors.orange),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'La hora del equipo está desviada ${timeSync.offset.inSeconds.abs()}s respecto al servidor. Se usará la hora sincronizada.',
                                  style: const TextStyle(fontSize: 13, color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Icon(Icons.document_scanner, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      const Text('Seleccione el kiosko',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text('Elija a qué kiosko físico corresponde este equipo',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      ...kioskos.map((k) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildKioskoCard(context, k, areaProvider, settings),
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKioskoCard(BuildContext context, KioskoFisico k, AreaProvider areaProvider, SettingsProvider settings) {
    final areas = k.areaIds.map((id) {
      final a = areaProvider.areaById(id);
      return a?.nombre;
    }).whereType<String>().toList();
    final isSelected = k.id == settings.selectedKioskoId;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () async {
          await settings.setSelectedKioskoId(k.id, areaIds: k.areaIds, logoUrl: k.logoUrl, videoUrl: k.videoUrl, nombre: k.nombre);
          await _loadPrinterConfig(k.id);
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/ticket');
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.success : AppColors.border,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
                      _buildLogoPreview(kiosko: k),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(k.nombre,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Actual', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                          ),
                        if (k.esHuerfano)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Pendiente', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    if (k.ubicacion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(k.ubicacion,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    if (areas.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(areas.join(', '),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (k.logoUrl != null && k.logoUrl!.isNotEmpty)
                          _badge(Icons.image, 'Logo', AppColors.success),
                        if ((k.logoUrl != null && k.logoUrl!.isNotEmpty) && (k.videoUrl != null && k.videoUrl!.isNotEmpty))
                          const SizedBox(width: 8),
                        if (k.videoUrl != null && k.videoUrl!.isNotEmpty)
                          _badge(Icons.videocam, 'Video', AppColors.success),
                        if ((k.logoUrl == null || k.logoUrl!.isEmpty) && (k.videoUrl == null || k.videoUrl!.isEmpty))
                          Text('Sin multimedia asignada',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _buildLogoPreview({KioskoFisico? kiosko}) {
    final logoUrl = kiosko?.logoUrl ?? '';
    if (logoUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.document_scanner, size: 28, color: AppColors.textSecondary),
      );
    }

    if (AreaLogoPreset.isPreset(logoUrl)) {
      final parsed = AreaLogoPreset.parse(logoUrl);
      if (parsed != null) {
        final preset = presetLogos.where((p) => p.id == parsed.$1).firstOrNull;
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: parsed.$2.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(preset?.icon ?? Icons.business, size: 28, color: parsed.$2),
        );
      }
    }

    final provider = safeImageProvider(logoUrl);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
        color: provider == null ? Colors.grey[100] : null,
      ),
      child: provider == null
          ? const Icon(Icons.broken_image, size: 28, color: AppColors.textSecondary)
          : null,
    );
  }
}
