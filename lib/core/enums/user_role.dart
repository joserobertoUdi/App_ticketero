enum UserRole {
  administrador,
  supervisor,
  operador,
  llamador;

  String get displayName {
    switch (this) {
      case UserRole.administrador:
        return 'Administrador';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.operador:
        return 'Operador';
      case UserRole.llamador:
        return 'Llamador';
    }
  }

  String get apiValue {
    return name;
  }

  static UserRole fromApiValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.operador,
    );
  }

  bool get isAdmin {
    return this == UserRole.administrador;
  }

  bool get isSupervisor {
    return this == UserRole.supervisor;
  }

  bool get isOperator {
    return this == UserRole.operador;
  }

  bool get isCaller {
    return this == UserRole.llamador;
  }
}