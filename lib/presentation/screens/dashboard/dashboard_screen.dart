import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/area_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/hourly_bar_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final areaProvider = Provider.of<AreaProvider>(context, listen: false);
      if (!auth.isAdmin && auth.isAttentionUser) {
        final areaNombres = auth.user?.areasAtencion
            .map((id) => areaProvider.areaById(id)?.nombre ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ?? [];
        Provider.of<DashboardProvider>(context, listen: false).setFilterAreas(areaNombres);
      }
      Provider.of<DashboardProvider>(context, listen: false).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isAdmin) {
                return Consumer<DashboardProvider>(
                  builder: (context, dp, _) {
                    return IconButton(
                      icon: dp.isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      tooltip: 'Exportar PDF',
                      onPressed: dp.isExporting
                          ? null
                          : () async {
                              final path = await dp.exportPdf();
                              if (path != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('PDF guardado en: $path'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isAdmin || auth.isSupervisor) {
                return IconButton(
                  icon: const Icon(Icons.monitor_heart),
                  tooltip: 'Monitoreo de Puestos',
                  onPressed: () => Navigator.pushNamed(context, '/puestos'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Configuración',
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, _) {
          if (dashboard.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final auth = Provider.of<AuthProvider>(context);
          final isOperator = auth.isAttentionUser;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPeriodSelector(dashboard),
                const SizedBox(height: 12),
                if (dashboard.summary != null && !isOperator) ...[
                  _buildSummaryCards(dashboard.summary!),
                  const SizedBox(height: 12),
                ],
                Expanded(child: _buildChartsSection(dashboard)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(DashboardProvider dashboard) {
    return Row(
      children: DashboardPeriod.values.map((period) {
        final isSelected = dashboard.selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(_periodLabel(period), style: const TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (_) => dashboard.setPeriod(period),
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }

  String _periodLabel(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.hoy:
        return 'Hoy';
      case DashboardPeriod.semana:
        return 'Semana';
      case DashboardPeriod.mes:
        return 'Mes';
    }
  }

  Widget _buildSummaryCards(dynamic stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Tickets',
            value: stats.totalTickets.toString(),
            icon: Icons.confirmation_number,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Atendidos',
            value: stats.totalAtendidos.toString(),
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Tiempo Prom.',
            value: stats.tiempoPromedioAtencionFormateado,
            icon: Icons.timer,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Pendientes',
            value: stats.totalPendientes.toString(),
            icon: Icons.hourglass_empty,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection(DashboardProvider dashboard) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tickets por Hora',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Expanded(
                    child: HourlyBarChart(
                      data: dashboard.hourlyBreakdown,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tickets por Área',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 12,
                              dataRowMinHeight: 32,
                              dataRowMaxHeight: 32,
                              headingRowHeight: 36,
                              columns: const [
                                DataColumn(label: Text('Área', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('Total', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('Prom.', style: TextStyle(fontSize: 12))),
                              ],
                              rows: dashboard.areaStats.map((stat) {
                                return DataRow(cells: [
                                  DataCell(Text(stat.area, style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('${stat.atendidos}/${stat.total}', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(
                                      '${stat.tiempoPromedioSegundos ~/ 60}:${(stat.tiempoPromedioSegundos % 60).toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 12))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rendimiento por Agente',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 12,
                              dataRowMinHeight: 32,
                              dataRowMaxHeight: 32,
                              headingRowHeight: 36,
                              columns: const [
                                DataColumn(label: Text('Agente', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('Atend.', style: TextStyle(fontSize: 12))),
                                DataColumn(label: Text('Prom.', style: TextStyle(fontSize: 12))),
                              ],
                              rows: dashboard.userStats.map((stat) {
                                return DataRow(cells: [
                                  DataCell(Text(stat.nombre, style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('${stat.totalAtendidos}', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(
                                      '${stat.tiempoPromedioSegundos ~/ 60}:${(stat.tiempoPromedioSegundos % 60).toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 12))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 20,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
