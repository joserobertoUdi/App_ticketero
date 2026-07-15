class AppValidators {
  AppValidators._();

  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese su usuario';
    }
    if (value.trim().length < 3) {
      return 'El usuario debe tener al menos 3 caracteres';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? nombreCompleto(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese el nombre completo';
    }
    if (value.trim().length < 5) {
      return 'Ingrese nombre y apellido';
    }
    return null;
  }

  static String? areaPrefijo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese el prefijo del área';
    }
    if (value.trim().length < 2 || value.trim().length > 10) {
      return 'El prefijo debe tener entre 2 y 10 caracteres';
    }
    return null;
  }

  static String? numeroPositivo(String? value, {String fieldName = 'Valor'}) {
    if (value == null || value.isEmpty) return '$fieldName es requerido';
    final number = int.tryParse(value);
    if (number == null || number <= 0) {
      return 'Ingrese un número válido mayor a 0';
    }
    return null;
  }
}
