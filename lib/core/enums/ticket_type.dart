enum TicketType {
  incidente,
  solicitud,
  problema,
  cambio,
  consulta;

  String get displayName {
    switch (this) {
      case TicketType.incidente:
        return 'Incidente';
      case TicketType.solicitud:
        return 'Solicitud';
      case TicketType.problema:
        return 'Problema';
      case TicketType.cambio:
        return 'Cambio';
      case TicketType.consulta:
        return 'Consulta';
    }
  }

  String get apiValue {
    return name;
  }

  static TicketType fromApiValue(String value) {
    return TicketType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => TicketType.incidente,
    );
  }
}
