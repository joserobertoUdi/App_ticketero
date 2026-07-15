import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel {
  final int totalTickets;
  final int totalAtendidos;
  final int totalPendientes;
  final int tiempoPromedioAtencionSegundos;
  final String tiempoPromedioAtencionFormateado;
  final int tiempoPromedioEsperaSegundos;
  final String tiempoPromedioEsperaFormateado;
  final String? periodoInicio;
  final String? periodoFin;

  const DashboardStatsModel({
    required this.totalTickets,
    required this.totalAtendidos,
    required this.totalPendientes,
    required this.tiempoPromedioAtencionSegundos,
    required this.tiempoPromedioAtencionFormateado,
    required this.tiempoPromedioEsperaSegundos,
    required this.tiempoPromedioEsperaFormateado,
    this.periodoInicio,
    this.periodoFin,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalTickets: json['totalTickets'] as int,
      totalAtendidos: json['totalAtendidos'] as int,
      totalPendientes: json['totalPendientes'] as int,
      tiempoPromedioAtencionSegundos:
          json['tiempoPromedioAtencion'] as int? ??
              json['tiempoPromedioAtencionSegundos'] as int? ??
              0,
      tiempoPromedioAtencionFormateado:
          json['tiempoPromedioAtencionFormateado'] as String? ?? '00:00',
      tiempoPromedioEsperaSegundos:
          json['tiempoPromedioEspera'] as int? ??
              json['tiempoPromedioEsperaSegundos'] as int? ??
              0,
      tiempoPromedioEsperaFormateado:
          json['tiempoPromedioEsperaFormateado'] as String? ?? '00:00',
      periodoInicio: json['periodo']?['inicio'] as String?,
      periodoFin: json['periodo']?['fin'] as String?,
    );
  }

  DashboardStats toEntity() {
    return DashboardStats(
      totalTickets: totalTickets,
      totalAtendidos: totalAtendidos,
      totalPendientes: totalPendientes,
      tiempoPromedioAtencionSegundos: tiempoPromedioAtencionSegundos,
      tiempoPromedioAtencionFormateado: tiempoPromedioAtencionFormateado,
      tiempoPromedioEsperaSegundos: tiempoPromedioEsperaSegundos,
      tiempoPromedioEsperaFormateado: tiempoPromedioEsperaFormateado,
      periodoInicio: periodoInicio != null
          ? DateTime.parse(periodoInicio!)
          : DateTime.now(),
      periodoFin:
          periodoFin != null ? DateTime.parse(periodoFin!) : DateTime.now(),
    );
  }
}
