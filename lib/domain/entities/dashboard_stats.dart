class DashboardStats {
  final int totalTickets;
  final int totalAtendidos;
  final int totalPendientes;
  final int tiempoPromedioAtencionSegundos;
  final String tiempoPromedioAtencionFormateado;
  final int tiempoPromedioEsperaSegundos;
  final String tiempoPromedioEsperaFormateado;
  final DateTime periodoInicio;
  final DateTime periodoFin;

  const DashboardStats({
    required this.totalTickets,
    required this.totalAtendidos,
    required this.totalPendientes,
    required this.tiempoPromedioAtencionSegundos,
    required this.tiempoPromedioAtencionFormateado,
    required this.tiempoPromedioEsperaSegundos,
    required this.tiempoPromedioEsperaFormateado,
    required this.periodoInicio,
    required this.periodoFin,
  });

  double get porcentajeAtendidos {
    if (totalTickets == 0) return 0;
    return (totalAtendidos / totalTickets) * 100;
  }
}

class AreaStats {
  final String area;
  final int total;
  final int atendidos;
  final int pendientes;
  final int tiempoPromedioSegundos;

  const AreaStats({
    required this.area,
    required this.total,
    required this.atendidos,
    required this.pendientes,
    required this.tiempoPromedioSegundos,
  });
}

class UserStats {
  final String nombre;
  final int totalAtendidos;
  final int tiempoPromedioSegundos;

  const UserStats({
    required this.nombre,
    required this.totalAtendidos,
    required this.tiempoPromedioSegundos,
  });
}

class HourlyBreakdown {
  final int hora;
  final int total;

  const HourlyBreakdown({
    required this.hora,
    required this.total,
  });
}
