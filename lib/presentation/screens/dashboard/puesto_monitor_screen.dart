import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/puesto_monitor_provider.dart';
import '../../../core/theme/app_colors.dart';

class PuestoMonitorScreen extends StatefulWidget {
  const PuestoMonitorScreen({super.key});

  @override
  State<PuestoMonitorScreen> createState() => _PuestoMonitorScreenState();
}

class _PuestoMonitorScreenState extends State<PuestoMonitorScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;
    await Provider.of<PuestoMonitorProvider>(context, listen: false)
        .loadPuestosStatus();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'atendiendo':
        return AppColors.success;
      case 'libre':
        return AppColors.warning;
      case 'no_esta':
        return Colors.grey;
      case 'inhabilitado':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'atendiendo':
        return 'Atendiendo';
      case 'libre':
        return 'Libre';
      case 'no_esta':
        return 'No está';
      case 'inhabilitado':
        return 'Inhabilitado';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'atendiendo':
        return Icons.headset_mic;
      case 'libre':
        return Icons.check_circle_outline;
      case 'no_esta':
        return Icons.person_off;
      case 'inhabilitado':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated || (!auth.isAdmin && !auth.isSupervisor)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo de Puestos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Consumer<PuestoMonitorProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.areas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.areas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!,
                      style: TextStyle(color: Colors.red[600])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.areas.isEmpty) {
            return const Center(
              child: Text('No hay puestos configurados',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.areas.length,
              itemBuilder: (context, index) {
                final area = provider.areas[index];
                final atendiendo = area.puestos
                    .where((p) => p.status == 'atendiendo')
                    .length;
                final libre = area.puestos
                    .where((p) => p.status == 'libre')
                    .length;
                final noEsta = area.puestos
                    .where((p) => p.status == 'no_esta')
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Row(
                      children: [
                        Text(area.areaNombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        _miniBadge(atendiendo, AppColors.success, 'A'),
                        const SizedBox(width: 4),
                        _miniBadge(libre, AppColors.warning, 'L'),
                        const SizedBox(width: 4),
                        _miniBadge(noEsta, Colors.grey, 'N'),
                      ],
                    ),
                    subtitle: Text('${area.totalPuestos} puestos'),
                    children: area.puestos.map((puesto) {
                      final color = _statusColor(puesto.status);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Icon(
                            _statusIcon(puesto.status),
                            color: color,
                            size: 20,
                          ),
                        ),
                        title: Text(puesto.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          puesto.operadorNombre != null
                              ? '${_statusLabel(puesto.status)} - ${puesto.operadorNombre}'
                              : _statusLabel(puesto.status),
                          style: TextStyle(color: color),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusLabel(puesto.status),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _miniBadge(int count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label:$count',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}