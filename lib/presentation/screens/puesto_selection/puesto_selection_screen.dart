import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/entities/puesto_info.dart';
import '../../providers/auth_provider.dart';

class PuestoSelectionScreen extends StatefulWidget {
  const PuestoSelectionScreen({super.key});

  @override
  State<PuestoSelectionScreen> createState() => _PuestoSelectionScreenState();
}

class _PuestoSelectionScreenState extends State<PuestoSelectionScreen> {
  int? _selectedPuestoId;
  int? _areaId;
  List<PuestoInfo> _puestos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _areaId = auth.user?.areaId;
    _loadPuestos();
  }

  Future<void> _loadPuestos() async {
    if (_areaId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final response = await api.get(ApiConstants.puestosByArea(_areaId!));
      final list = (response.data as List?) ?? [];
      _puestos = list.map((e) {
        final m = e as Map<String, dynamic>;
        return PuestoInfo(
          id: m['id'] as int,
          nombre: m['nombre'] as String? ?? '',
          occupiedByUserId: (m['ocupado'] as bool?) == true ? m['id'] as int : null,
        );
      }).toList();
    } catch (_) {
      _puestos = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _confirm() async {
    if (_selectedPuestoId == null || _areaId == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final puesto = _puestos.firstWhere((p) => p.id == _selectedPuestoId);
    auth.setPuestoSeleccionado(puesto.nombre, areaId: _areaId, puestoId: _selectedPuestoId);

    final error = await auth.openSession(auth.user!.id, _selectedPuestoId!);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir sesión: $error'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/attention');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : _puestos.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text('No hay puestos disponibles para su área',
                              style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          const Text('Contacte al administrador',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Provider.of<AuthProvider>(context, listen: false).logout();
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Cerrar sesión'),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.desk_outlined, size: 64, color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Seleccione su puesto de atención',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toque el recuadro que corresponda a su ubicación física',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: _puestos.map((p) => _buildPuestoCard(p)).toList(),
                            ),
                            if (_selectedPuestoId != null) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: _confirm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textOnPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Confirmar',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildPuestoCard(PuestoInfo puesto) {
    final isSelected = _selectedPuestoId == puesto.id;
    final isOccupied = puesto.occupiedByUserId != null;
    final canSelect = !isOccupied;

    return Material(
      color: isSelected
          ? AppColors.primary.withOpacity(0.12)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: canSelect
            ? () => setState(() => _selectedPuestoId = puesto.id)
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isOccupied
                      ? Colors.orange.withOpacity(0.4)
                      : AppColors.border,
              width: isSelected ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOccupied ? Icons.lock : Icons.meeting_room_outlined,
                size: 40,
                color: isOccupied
                    ? Colors.orange
                    : isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                puesto.nombre,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isOccupied
                      ? Colors.orange
                      : isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (isOccupied) ...[
                const SizedBox(height: 6),
                Text(
                  'Ocupado',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(Icons.check_circle, size: 28, color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
