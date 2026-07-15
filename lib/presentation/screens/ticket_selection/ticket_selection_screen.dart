import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/printing/printing_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/area_logo_presets.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/service_type.dart';
import '../../providers/area_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/area_selector_card.dart';
import 'widgets/ticket_display.dart';
import 'widgets/background_video_widget.dart';
import 'widgets/step_indicator.dart';
import 'widgets/service_type_card.dart';

class TicketSelectionScreen extends StatefulWidget {
  const TicketSelectionScreen({super.key});

  @override
  State<TicketSelectionScreen> createState() => _TicketSelectionScreenState();
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  int _currentStep = 0;
  int? _selectedAreaId;
  ServiceType? _selectedServiceType;
  bool _isHeaderVisible = false;
  bool _headerLocked = false;
  Timer? _resetTimer;
  bool _configChecked = false;
  List<ServiceType> _serviceTypes = [];
  bool _isLoadingServices = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AreaProvider>(context, listen: false).loadAreas();
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onAreaSelected(int areaId) {
    _resetTimer?.cancel();
    _resetTimer = null;
    Provider.of<TicketProvider>(context, listen: false).clearCurrentTicket();
    setState(() {
      _selectedAreaId = areaId;
      _selectedServiceType = null;
      _currentStep = 1;
    });
    _loadServiceTypes(areaId);
  }

  Future<void> _loadServiceTypes(int areaId) async {
    setState(() => _isLoadingServices = true);
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final response = await api.get(ApiConstants.serviciosByArea(areaId));
      final list = (response.data as List?) ?? [];
      _serviceTypes = list.map((e) {
        final m = e as Map<String, dynamic>;
        return ServiceType(
          id: m['id'] as int,
          areaId: areaId,
          nombre: m['nombre'] as String? ?? '',
          iconName: m['icono'] as String? ?? 'help_outline',
        );
      }).toList();
    } catch (_) {
      _serviceTypes = [];
    }
    if (mounted) setState(() => _isLoadingServices = false);
  }

  void _onServiceTypeSelected(ServiceType serviceType) {
    setState(() {
      _selectedServiceType = serviceType;
      _currentStep = 2;
    });
    _generateTicket();
  }

  void _goBack() {
    _resetTimer?.cancel();
    _resetTimer = null;
    setState(() {
      if (_currentStep == 2) {
        _currentStep = 1;
        _selectedServiceType = null;
      } else if (_currentStep == 1) {
        _currentStep = 0;
        _selectedAreaId = null;
      }
    });
  }

  void _generateTicket() async {
    if (_selectedAreaId == null || _selectedServiceType == null) return;
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final areaProvider = Provider.of<AreaProvider>(context, listen: false);
    final area = areaProvider.areaById(_selectedAreaId!);
    final success = await ticketProvider.createTicket(
      _selectedAreaId!,
      areaName: area?.nombre,
      servicioId: _selectedServiceType?.id,
    );
    if (success && mounted) {
      setState(() {});
      _printTicket(ticketProvider);
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) {
          ticketProvider.clearCurrentTicket();
          setState(() {
            _currentStep = 0;
            _selectedAreaId = null;
            _selectedServiceType = null;
          });
        }
      });
    }
  }

  void _printTicket(TicketProvider ticketProvider) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final tiempoEstimadoPorTicket = settingsProvider.tiempoEstimadoMinutos;
    final areaId = _selectedAreaId ?? 0;
    final personasEnCola = ticketProvider.pendingCountForArea(areaId);

    final printData = ticketProvider.getPrintData(tiempoEstimadoPorTicket, personasEnCola);
    if (printData == null) return;

    final printingProvider =
        Provider.of<PrintingProvider>(context, listen: false);
    if (!printingProvider.isConfigured) {
      AppLogger.info('Print', 'Impresora no configurada, ticket no impreso');
      return;
    }

    printingProvider.printTicket(printData).then((result) {
      if (!result.success && mounted) {
        AppLogger.warn('Print',
            'Error al imprimir ticket: ${result.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: ${result.errorMessage}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final videoUrl = settings.selectedKioskoVideoUrl;
        final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (hasVideo)
                BackgroundVideoWidget(videoUrl: videoUrl),
              SafeArea(
                child: Column(
                  children: [
                    Container(
                      color: Colors.white.withValues(alpha: 0.75),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _isHeaderVisible = true),
                        onExit: (_) => setState(() => _isHeaderVisible = false),
                        opaque: true,
                        child: AnimatedOpacity(
                          opacity: _isHeaderVisible || _headerLocked ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child:                           _buildHeader(settings.selectedKioskoLogoUrl, settings.selectedKioskoNombre),
                        ),
                      ),
                    ),
                    Expanded(child: _buildContent()),
                    Container(
                      color: Colors.white.withValues(alpha: 0.75),
                      child: AnimatedOpacity(
                        opacity: _isHeaderVisible || _headerLocked ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: _buildBottomBar(hasVideo),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoWidget(String? logoUrl) {
    if (logoUrl == null || logoUrl.isEmpty) return const SizedBox.shrink();
    if (AreaLogoPreset.isPreset(logoUrl)) {
      final parsed = AreaLogoPreset.parse(logoUrl);
      if (parsed != null) {
        final preset = presetLogos.where((p) => p.id == parsed.$1).firstOrNull;
        return Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          child: Icon(preset?.icon ?? Icons.business, size: 22, color: Colors.white70),
        );
      }
    }
    final provider = safeImageProvider(logoUrl);
    if (provider != null) {
      return Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(image: provider, fit: BoxFit.cover),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader(String? logoUrl, String kioskoNombre) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              _buildLogoWidget(logoUrl),
              Expanded(
                child: Text(
                  kioskoNombre.isNotEmpty ? kioskoNombre : 'Bienvenido al Sistema de Tickets',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _headerLocked = !_headerLocked),
                child: Icon(
                  _headerLocked ? Icons.lock : Icons.lock_open,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/kiosko-selection'),
                child: const Icon(Icons.settings, color: Colors.white70, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _currentStep == 0
                ? 'Seleccione el área de atención deseada'
                : _currentStep == 1
                    ? 'Seleccione el tipo de servicio'
                    : 'Su ticket ha sido generado',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          StepIndicator(
            currentStep: _currentStep,
            totalSteps: 3,
            labels: const ['Área', 'Servicio', 'Ficha'],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer2<AreaProvider, TicketProvider>(
      builder: (context, areaProvider, ticketProvider, _) {
        Widget stepContent;
        if (_currentStep == 0) {
          stepContent = _buildAreaStep(areaProvider, ticketProvider);
        } else if (_currentStep == 1) {
          stepContent = _buildServiceTypeStep();
        } else {
          stepContent = _buildTicketStep(ticketProvider);
        }

        return Container(
          color: Colors.white.withValues(alpha: 0.75),
          child: stepContent,
        );
      },
    );
  }

  Widget _buildAreaStep(AreaProvider areaProvider, TicketProvider ticketProvider) {
    if (ticketProvider.currentTicket != null) {
      return Center(
        child: TicketDisplay(
          ticket: ticketProvider.currentTicket!,
          onDismiss: () {
            ticketProvider.clearCurrentTicket();
            setState(() {
              _currentStep = 0;
              _selectedAreaId = null;
              _selectedServiceType = null;
            });
          },
        ),
      );
    }

    if (areaProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final kioskoAreas = settings.kioskoAreaIds;
    final filteredAreas = kioskoAreas.isNotEmpty
        ? areaProvider.activeAreas.where((a) => kioskoAreas.contains(a.id)).toList()
        : areaProvider.activeAreas;

    if (filteredAreas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('No hay áreas configuradas para este kiosko',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/kiosko-selection'),
              child: const Text('Cambiar kiosko'),
            ),
          ],
        ),
      );
    }

    if (filteredAreas.length == 1 && _selectedAreaId == null && !_configChecked) {
      _configChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onAreaSelected(filteredAreas.first.id);
      });
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: filteredAreas.length > 1 ? 2 : 1,
        childAspectRatio: 2.5,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: filteredAreas.length,
      itemBuilder: (context, index) {
        final area = filteredAreas[index];
        return AreaSelectorCard(
          area: area,
          onTap: () => _onAreaSelected(area.id),
        );
      },
    );
  }

  Widget _buildServiceTypeStep() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingServices
              ? const Center(child: CircularProgressIndicator())
              : _serviceTypes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text(
                            'No hay servicios configurados para esta área',
                            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(80, 24, 80, 0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _serviceTypes.length,
                      itemBuilder: (context, index) {
                        final st = _serviceTypes[index];
                        return ServiceTypeCard(
                          label: st.nombre,
                          icon: st.icon,
                          isSelected: _selectedServiceType?.id == st.id,
                          onTap: () => _onServiceTypeSelected(st),
                        );
                      },
                    ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBackButton(),
        ),
      ],
    );
  }

  Widget _buildTicketStep(TicketProvider ticketProvider) {
    if (ticketProvider.currentTicket == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: TicketDisplay(
        ticket: ticketProvider.currentTicket!,
        onDismiss: () {
          ticketProvider.clearCurrentTicket();
          setState(() {
            _currentStep = 0;
            _selectedAreaId = null;
            _selectedServiceType = null;
          });
        },
      ),
    );
  }

  Widget _buildBottomBar(bool hasVideo) {
    return Container(
      height: 48,
      color: Colors.white.withValues(alpha: hasVideo ? 0.75 : 1),
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
        icon: const Icon(Icons.admin_panel_settings,
            color: Colors.grey),
        label: const Text(
          'Acceso del Personal',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return ElevatedButton.icon(
      onPressed: _goBack,
      icon: const Icon(Icons.arrow_back, size: 18),
      label: const Text('Volver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
        shadowColor: const Color(0xFF64B5F6).withValues(alpha: 0.4),
      ),
    );
  }
}
