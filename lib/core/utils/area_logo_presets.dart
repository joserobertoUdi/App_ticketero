import 'package:flutter/material.dart';

class AreaLogoPreset {
  final IconData icon;
  final Color color;
  final String label;
  final String id;

  const AreaLogoPreset({
    required this.icon,
    required this.color,
    required this.label,
    required this.id,
  });

  String get storageKey => '@preset\$$id\$${color.toARGB32()}';

  static (String id, Color color)? parse(String logoUrl) {
    if (!logoUrl.startsWith('@preset\$')) return null;
    final parts = logoUrl.substring('@preset\$'.length).split('\$');
    if (parts.length != 2) return null;
    final colorVal = int.tryParse(parts[1]);
    if (colorVal == null) return null;
    return (parts[0], Color(colorVal));
  }

  static bool isPreset(String logoUrl) => logoUrl.startsWith('@preset\$');
}

const presetLogos = [
  AreaLogoPreset(icon: Icons.point_of_sale, color: Color(0xFFE30613), label: 'Caja', id: 'caja'),
  AreaLogoPreset(icon: Icons.payments, color: Color(0xFFE30613), label: 'Pagos', id: 'pagos'),
  AreaLogoPreset(icon: Icons.info_outline, color: Color(0xFFE30613), label: 'Informes', id: 'informes'),
  AreaLogoPreset(icon: Icons.contact_mail, color: Color(0xFFE30613), label: 'Atención', id: 'atencion'),
  AreaLogoPreset(icon: Icons.app_registration, color: Color(0xFFE30613), label: 'Inscripciones', id: 'inscripciones'),
  AreaLogoPreset(icon: Icons.description, color: Color(0xFFE30613), label: 'Documentación', id: 'documentacion'),
  AreaLogoPreset(icon: Icons.assignment, color: Color(0xFFE30613), label: 'Trámites', id: 'tramites'),
  AreaLogoPreset(icon: Icons.support_agent, color: Color(0xFFE30613), label: 'Soporte', id: 'soporte'),
  AreaLogoPreset(icon: Icons.local_hospital, color: Color(0xFFE30613), label: 'Salud', id: 'salud'),
  AreaLogoPreset(icon: Icons.school, color: Color(0xFFE30613), label: 'Educación', id: 'educacion'),
  AreaLogoPreset(icon: Icons.account_balance, color: Color(0xFFE30613), label: 'Gobierno', id: 'gobierno'),
  AreaLogoPreset(icon: Icons.business, color: Color(0xFFE30613), label: 'Empresa', id: 'empresa'),
];
