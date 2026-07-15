import 'package:flutter/material.dart';

class ServiceType {
  final int id;
  final int areaId;
  final String nombre;
  final String iconName;

  const ServiceType({
    required this.id,
    required this.areaId,
    required this.nombre,
    this.iconName = 'help_outline',
  });

  IconData get icon => _iconMap[iconName] ?? Icons.help_outline;

  static const Map<String, IconData> _iconMap = {
    'payments': Icons.payments,
    'search': Icons.search,
    'money_off': Icons.money_off,
    'live_help': Icons.live_help,
    'explore': Icons.explore,
    'description': Icons.description,
    'app_registration': Icons.app_registration,
    'refresh': Icons.refresh,
    'remove_circle': Icons.remove_circle,
    'inbox': Icons.inbox,
    'outbox': Icons.outbox,
    'find_in_page': Icons.find_in_page,
    'receipt': Icons.receipt,
    'assignment': Icons.assignment,
    'fact_check': Icons.fact_check,
    'support_agent': Icons.support_agent,
    'handshake': Icons.handshake,
    'help_outline': Icons.help_outline,
  };

  static const List<Map<String, dynamic>> iconOptions = [
    {'name': 'Por defecto', 'icon': 'help_outline'},
    {'name': 'Pago', 'icon': 'payments'},
    {'name': 'Búsqueda', 'icon': 'search'},
    {'name': 'Efectivo', 'icon': 'money_off'},
    {'name': 'Ayuda', 'icon': 'live_help'},
    {'name': 'Explorar', 'icon': 'explore'},
    {'name': 'Documento', 'icon': 'description'},
    {'name': 'Registro', 'icon': 'app_registration'},
    {'name': 'Renovar', 'icon': 'refresh'},
    {'name': 'Quitar', 'icon': 'remove_circle'},
    {'name': 'Entrada', 'icon': 'inbox'},
    {'name': 'Salida', 'icon': 'outbox'},
    {'name': 'Buscar', 'icon': 'find_in_page'},
    {'name': 'Recibo', 'icon': 'receipt'},
    {'name': 'Tarea', 'icon': 'assignment'},
    {'name': 'Verificar', 'icon': 'fact_check'},
    {'name': 'Atención', 'icon': 'support_agent'},
    {'name': 'Acuerdo', 'icon': 'handshake'},
  ];

  static IconData iconByName(String name) =>
      _iconMap[name] ?? Icons.help_outline;

  ServiceType copyWith({
    int? id,
    int? areaId,
    String? nombre,
    String? iconName,
  }) {
    return ServiceType(
      id: id ?? this.id,
      areaId: areaId ?? this.areaId,
      nombre: nombre ?? this.nombre,
      iconName: iconName ?? this.iconName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'areaId': areaId,
        'nombre': nombre,
        'iconName': iconName,
      };

  factory ServiceType.fromJson(Map<String, dynamic> json) => ServiceType(
        id: json['id'] as int,
        areaId: json['areaId'] as int,
        nombre: json['nombre'] as String,
        iconName: (json['iconName'] as String?) ?? (json['icono'] as String?) ?? 'help_outline',
      );
}
