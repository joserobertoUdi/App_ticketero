import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../domain/entities/area.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/area_logo_presets.dart';
import '../../../../core/utils/image_utils.dart';

class AreaSelectorCard extends StatelessWidget {
  final Area area;
  final VoidCallback onTap;

  const AreaSelectorCard({
    super.key,
    required this.area,
    required this.onTap,
  });

  Widget _buildLogo() {
    if (area.logoUrl.isNotEmpty) {
      if (AreaLogoPreset.isPreset(area.logoUrl)) {
        final parsed = AreaLogoPreset.parse(area.logoUrl);
        if (parsed != null) {
          final preset = presetLogos.where((p) => p.id == parsed.$1).firstOrNull;
          if (preset != null) {
            return Icon(preset.icon, size: 36, color: parsed.$2);
          }
        }
      } else {
        return CircleAvatar(
          radius: 18,
          backgroundImage: area.logoUrl.startsWith('http')
              ? NetworkImage(area.logoUrl)
              : safeImageProvider(area.logoUrl),
          backgroundColor: Colors.grey[200],
        );
      }
    }
    return Icon(_getAreaIcon(), size: 36, color: AppColors.primary);
  }

  IconData _getAreaIcon() {
    switch (area.nombre.toLowerCase()) {
      case 'caja':
        return Icons.payments;
      case 'información':
      case 'informacion':
        return Icons.info;
      case 'inscripción':
      case 'inscripcion':
        return Icons.app_registration;
      case 'documentación':
      case 'documentacion':
        return Icons.description;
      default:
        return Icons.business;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.75),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(width: 14),
                  Text(
                    area.nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
