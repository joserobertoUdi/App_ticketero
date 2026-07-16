import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/area_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

enum AgentState { libre, enAtencion, pausa }

class AttentionScreen extends StatefulWidget {
  const AttentionScreen({super.key});

  @override
  State<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends State<AttentionScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;

  int _elapsedSeconds = 0;
  AgentState _agentState = AgentState.libre;
  late AnimationController _blinkController;

  final FocusNode _focusNode = FocusNode();
  Map<String, dynamic>? _userStats;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      Provider.of<AreaProvider>(context, listen: false).loadAreas();
      _fetchUserStats();
      _refreshPending();
    });
  }

  void _refreshPending() {
    Provider.of<TicketProvider>(context, listen: false)
        .refreshPendingForAreas(_userAreaIds);
  }

  Future<void> _fetchUserStats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    setState(() => _loadingStats = true);
    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);
      final response = await apiClient.get(
        '${ApiConstants.dashboardUserStats}/${user.id}',
      );
      if (mounted) {
        setState(() {
          _userStats = response.data as Map<String, dynamic>;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  List<int> get _userAreaIds {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null && user.areasAtencion.isNotEmpty) {
      return user.areasAtencion;
    }
    if (user?.areaId != null) return [user!.areaId!];
    return [1];
  }

  bool get _isActiveAttentionMine {
    final active = Provider.of<TicketProvider>(context, listen: false).activeAttention;
    if (active == null) return false;
    return _userAreaIds.contains(active.areaId);
  }

  Future<void> _callNext() async {
    if (_agentState == AgentState.enAtencion) return;
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id ?? 0;
    final puesto = auth.puestoSeleccionado ?? auth.user?.puesto;
    final areas = _userAreaIds;
    for (final areaId in areas) {
      final success = await ticketProvider.callNextTicket(areaId, puesto: puesto, userId: userId);
      if (success && mounted) {
        setState(() => _agentState = AgentState.libre);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ticketProvider.errorMessage ?? 'No hay tickets pendientes'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startAttention() async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (ticketProvider.activeAttention == null) return;
    if (!_userAreaIds.contains(ticketProvider.activeAttention!.areaId)) return;
    final success = await ticketProvider.startAttention(
      ticketProvider.activeAttention!.id,
      auth.user!.id,
      puestoId: auth.puestoId ?? 1,
    );
    if (success && mounted) {
      _startTimer();
      setState(() => _agentState = AgentState.enAtencion);
    }
  }

  Future<void> _completeAttention() async {
    if (_agentState != AgentState.enAtencion) return;
    final observacion = await _showObservationDialog();
    if (observacion == null) return;
    _stopTimer();
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await ticketProvider.completeAttention(
      ticketProvider.activeAttention!.id,
      auth.user!.id,
      observacion.isEmpty ? null : observacion,
    );
    setState(() => _agentState = AgentState.libre);
    _fetchUserStats();
  }

  Future<String?> _showObservationDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar Atención'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket: ${Provider.of<TicketProvider>(context, listen: false).activeAttention?.codigoTicket ?? ""}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            const Text('Observación (opcional):', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Notas sobre la atención...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Sin observación'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _togglePause() {
    if (_agentState == AgentState.enAtencion) return;
    setState(() {
      _agentState =
          _agentState == AgentState.pausa ? AgentState.libre : AgentState.pausa;
      if (_agentState == AgentState.pausa) {
        _stopTimer();
      }
    });
  }

  void _showDeriveDialog() {
    if (_agentState != AgentState.enAtencion) return;
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final ticket = ticketProvider.activeAttention;
    if (ticket == null) return;

    final areaProvider = Provider.of<AreaProvider>(context, listen: false);
    final areas = areaProvider.areas.where((a) => a.id != ticket.areaId && a.activo).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Derivar Ticket'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ticket: ${ticket.codigoTicket}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Area actual: ${ticket.areaNombre}'),
              const SizedBox(height: 16),
              const Text('Seleccione el area de destino:'),
              const SizedBox(height: 8),
              if (areas.isEmpty)
                const Text('No hay otras areas disponibles',
                    style: TextStyle(color: Colors.grey))
              else
                ...areas.map((area) => ListTile(
                      leading: const Icon(Icons.swap_horiz, color: Colors.orange),
                      title: Text(area.nombre),
                      subtitle: Text('Prefijo: ${area.prefijo}'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _deriveTicket(ticket.codigoTicket, area.id, area.nombre);
                      },
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _deriveTicket(String codigoTicket, int targetAreaId, String targetAreaNombre) async {
    final provider = Provider.of<TicketProvider>(context, listen: false);
    final ticketId = provider.activeAttention?.id;
    if (ticketId == null) return;

    _stopTimer();
    _agentState = AgentState.libre;

    final success = await provider.deriveTicket(ticketId, targetAreaId, 'Derivado a $targetAreaNombre');
    if (mounted) {
      setState(() => _agentState = AgentState.libre);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Ticket derivado a $targetAreaNombre'
              : provider.errorMessage ?? 'Error al derivar ticket'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
    _fetchUserStats();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.f1) {
      _callNext();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      _startAttention();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f3) {
      _completeAttention();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f4) {
      if (_agentState == AgentState.enAtencion) {
        _showDeriveDialog();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String get _elapsedFormatted {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _stateColor {
    switch (_agentState) {
      case AgentState.libre:
        return AppColors.success;
      case AgentState.enAtencion:
        return Colors.grey;
      case AgentState.pausa:
        return Colors.amber;
    }
  }

  String get _stateLabel {
    switch (_agentState) {
      case AgentState.libre:
        return 'LIBRE';
      case AgentState.enAtencion:
        return 'EN ATENCION';
      case AgentState.pausa:
        return 'PAUSA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<AuthProvider>(
            builder: (context, auth, _) => Text(
              'Atencion - ${auth.user?.nombreCompleto ?? ''}',
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _stateColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _stateLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (Provider.of<AuthProvider>(context).isAdmin ||
                Provider.of<AuthProvider>(context).isSupervisor ||
                Provider.of<AuthProvider>(context).isAttentionUser)
              IconButton(
                icon: const Icon(Icons.dashboard),
                tooltip: 'Dashboard',
                onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              ),
            if (Provider.of<AuthProvider>(context).isAdmin)
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configuracion',
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesion',
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: Consumer<TicketProvider>(
          builder: (context, ticketProvider, _) {
            final areaIds = _userAreaIds;
            final myPendingTickets = ticketProvider.pendingTicketsForAreas(areaIds);
            final myPendingCount = ticketProvider.pendingCountForAreas(areaIds);
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (_isActiveAttentionMine) ...[
                          _buildCurrentTicket(ticketProvider.activeAttention!),
                          const SizedBox(height: 24),
                          _buildTimerCard(),
                        ] else ...[
                          _buildWaitingCard(),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _agentState == AgentState.enAtencion
                                      ? null
                                      : _callNext,
                                  icon: const Icon(Icons.double_arrow, size: 28),
                                  label: const Text('LLAMAR (F1)',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isActiveAttentionMine &&
                                          _agentState != AgentState.enAtencion
                                      ? _startAttention
                                      : null,
                                  icon: const Icon(Icons.play_arrow, size: 28),
                                  label: const Text('INICIAR (F2)',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _agentState == AgentState.enAtencion
                                      ? _completeAttention
                                      : null,
                                  icon: const Icon(Icons.stop, size: 28),
                                  label: const Text('FINALIZAR (F3)',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: _agentState == AgentState.enAtencion
                                      ? _showDeriveDialog
                                      : null,
                                  icon: const Icon(Icons.swap_horiz, size: 20),
                                  label: const Text('DERIVAR (F4)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: _togglePause,
                                  icon: Icon(
                                    _agentState == AgentState.pausa
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                  ),
                                  label: Text(
                                    _agentState == AgentState.pausa
                                        ? 'REANUDAR'
                                        : 'PAUSA',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                            children: [
                              Text(
                                'En espera ($myPendingCount)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 3,
                          child: myPendingTickets.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.celebration, size: 40, color: Colors.grey[300]),
                                      const SizedBox(height: 8),
                                      Text('Cola vacía', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                                    ],
                                  ),
                                )
                              : AnimatedBuilder(
                                  animation: _blinkController,
                                  builder: (context, child) {
                                    return ListView.builder(
                                      itemCount: myPendingTickets.length,
                                      itemBuilder: (context, index) {
                                        final ticket = myPendingTickets[index];
                                        final isPriority = ticket.esPrioritario;
                                        final isDerived = ticket.derivadoDe != null;

                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 4),
                                          child: ListTile(
                                            dense: true,
                                            leading: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isPriority)
                                                  Container(
                                                    width: 4,
                                                    height: 32,
                                                    color: Colors.orange,
                                                  ),
                                                if (index == 0)
                                                  Icon(Icons.confirmation_number,
                                                      size: 20,
                                                      color: isPriority ? Colors.orange : AppColors.primary)
                                                else
                                                  Icon(Icons.confirmation_number,
                                                      size: 20,
                                                      color: Colors.grey[400]),
                                              ],
                                            ),
                                            title: Row(
                                              children: [
                                                if (isPriority)
                                                  Icon(Icons.flash_on,
                                                      size: 14, color: Colors.orange),
                                                if (isDerived)
                                                  Icon(Icons.swap_horiz,
                                                      size: 14, color: Colors.orange),
                                                const SizedBox(width: 4),
                                                Text(ticket.codigoTicket,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                        color: isPriority ? Colors.orange : null)),
                                              ],
                                            ),
                                            subtitle: Text(
                                              '${ticket.areaNombre}${isDerived ? ' (derivado)' : ''}',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            trailing: index == 0
                                                ? Icon(Icons.arrow_forward, size: 16, color: AppColors.primary)
                                                : null,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                        const Divider(),
                        Text(
                          'Historial Hoy',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 2,
                          child: _buildHistory(ticketProvider),
                        ),
                        if (Provider.of<AuthProvider>(context).isAttentionUser) ...[
                          const Divider(),
                          _buildPersonalMetrics(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistory(TicketProvider provider) {
    final areaIds = _userAreaIds.toSet();
    final logs = provider.attentionHistory
        .where((l) => l.areaId == null || areaIds.contains(l.areaId))
        .toList();
    if (logs.isEmpty) {
      return Center(
        child: Text('Sin atenciones hoy', style: TextStyle(color: Colors.grey[400])),
      );
    }
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final esDerivado =
            log.observacion != null && log.observacion!.startsWith('Derivado');
        return ListTile(
          dense: true,
          leading: Icon(
            esDerivado ? Icons.swap_horiz : Icons.check_circle,
            color: esDerivado ? Colors.orange : AppColors.success,
            size: 20,
          ),
          title: Text(log.codigoTicket ?? '', style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            log.observacion != null
                ? '${log.tiempoFormateado} · ${log.observacion}'
                : log.tiempoFormateado,
            style: const TextStyle(fontSize: 11),
          ),
        );
      },
    );
  }

  Widget _buildPersonalMetrics() {
    if (_loadingStats) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_userStats == null) return const SizedBox.shrink();

    final total = _userStats!['totalAtendidos'] as int? ?? 0;
    final hoy = _userStats!['totalHoy'] as int? ?? 0;
    final tiempoProm = _userStats!['tiempoPromedioFormateado'] as String? ?? '00:00';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis Metricas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _metricChip(Icons.today, 'Hoy', '$hoy', AppColors.primary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _metricChip(Icons.date_range, 'Semana', '$total', AppColors.success),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _metricChip(Icons.timer, 'Promedio', tiempoProm, AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCurrentTicket(dynamic ticket) {
    final isDerived = ticket.derivadoDe != null;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ticket Actual',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ticket.esPrioritario)
                  Icon(Icons.flash_on, size: 28, color: Colors.orange),
                if (isDerived)
                  Icon(Icons.swap_horiz, size: 28, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  ticket.codigoTicket,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.areaNombre,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
            if (isDerived)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Derivado de ${ticket.derivadoDeNombre}',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 32, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(
              _elapsedFormatted,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Card(
      elevation: 4,
      child: Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Esperando siguiente ticket...',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
