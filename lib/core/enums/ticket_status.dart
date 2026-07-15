enum TicketStatus {
  pendiente,
  llamado,
  en_atencion,
  completado,
  cancelado;

  String get displayName {
    switch (this) {
      case TicketStatus.pendiente:
        return 'Pendiente';
      case TicketStatus.llamado:
        return 'Llamado';
      case TicketStatus.en_atencion:
        return 'En Atención';
      case TicketStatus.completado:
        return 'Completado';
      case TicketStatus.cancelado:
        return 'Cancelado';
    }
  }

  String get apiValue {
    return name;
  }

  static TicketStatus fromApiValue(String value) {
    return TicketStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TicketStatus.pendiente,
    );
  }

  bool get isActive {
    return this == TicketStatus.pendiente ||
        this == TicketStatus.llamado ||
        this == TicketStatus.en_atencion;
  }

  bool get isTerminal {
    return this == TicketStatus.completado || this == TicketStatus.cancelado;
  }
}
