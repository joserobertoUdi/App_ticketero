import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../data/datasources/remote/dashboard_remote_datasource.dart';

class PuestoAreaStatus {
  final int areaId;
  final String areaNombre;
  final bool areaActiva;
  final int totalPuestos;
  final List<PuestoStatus> puestos;

  const PuestoAreaStatus({
    required this.areaId,
    required this.areaNombre,
    required this.areaActiva,
    required this.totalPuestos,
    required this.puestos,
  });

  factory PuestoAreaStatus.fromJson(Map<String, dynamic> json) {
    return PuestoAreaStatus(
      areaId: json['areaId'] as int? ?? 0,
      areaNombre: json['areaNombre'] as String? ?? '',
      areaActiva: json['areaActiva'] as bool? ?? false,
      totalPuestos: json['totalPuestos'] as int? ?? 0,
      puestos: json['puestos'] is List
          ? (json['puestos'] as List)
              .map((e) => PuestoStatus.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class PuestoStatus {
  final int puestoId;
  final String nombre;
  final String status;
  final int? operadorId;
  final String? operadorNombre;

  const PuestoStatus({
    required this.puestoId,
    required this.nombre,
    required this.status,
    this.operadorId,
    this.operadorNombre,
  });

  factory PuestoStatus.fromJson(Map<String, dynamic> json) {
    return PuestoStatus(
      puestoId: json['puestoId'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      status: json['status'] as String? ?? '',
      operadorId: json['operadorId'] as int?,
      operadorNombre: json['operadorNombre'] as String?,
    );
  }
}

class PuestoMonitorProvider extends ChangeNotifier {
  final DashboardRemoteDataSource _remote;
  List<PuestoAreaStatus> _areas = [];
  bool _isLoading = false;
  String? _errorMessage;

  PuestoMonitorProvider({required ApiClient apiClient})
      : _remote = DashboardRemoteDataSource(apiClient);

  List<PuestoAreaStatus> get areas => _areas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPuestosStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _remote.getPuestosStatus();
      final areasList = (result['areas'] as List?) ?? [];
      _areas = areasList
          .map((e) => PuestoAreaStatus.fromJson(e as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar estado de puestos';
      _isLoading = false;
      notifyListeners();
    }
  }
}