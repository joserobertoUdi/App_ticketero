import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/area_logo_presets.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../domain/entities/kiosko_media.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/settings_provider.dart';

class KioskoMediaPanel extends StatefulWidget {
  const KioskoMediaPanel({super.key});

  @override
  State<KioskoMediaPanel> createState() => _KioskoMediaPanelState();
}

class _KioskoMediaPanelState extends State<KioskoMediaPanel> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, AreaProvider>(
      builder: (context, settings, areaProvider, _) {
        final locations = settings.kioskoLocations;

        if (areaProvider.isLoading && areaProvider.areas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Gestión de Kioskos',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${locations.length} kioskos',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showEditDialog(context, null, areaProvider, settings),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo Kiosko'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              if (locations.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text('No hay kioskos configurados',
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: locations.length,
                    itemBuilder: (_, i) => _buildKioskoCard(context, locations[i], areaProvider, settings),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKioskoCard(BuildContext context, KioskoMedia loc, AreaProvider areaProvider, SettingsProvider settings) {
    final areaNames = loc.areaIds.map((id) {
      final a = areaProvider.areaById(id);
      return a?.nombre;
    }).whereType<String>().toList();
    final isSelected = loc.id == settings.selectedKioskoId;
    final hasLogo = loc.logoUrl.isNotEmpty;
    final hasVideo = loc.videoUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.success, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showKioskoDetail(context, loc, areaProvider, settings),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogoPreview(loc),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(loc.nombre,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Activo',
                                style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...areaNames.take(3).map((name) => Chip(
                              label: Text(name, style: const TextStyle(fontSize: 11)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                            )),
                        if (areaNames.length > 3)
                          Chip(
                            label: Text('+${areaNames.length - 3}', style: const TextStyle(fontSize: 11)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _mediaBadge(
                          Icons.image_outlined,
                          hasLogo ? 'Logo configurado' : 'Sin logo',
                          hasLogo ? AppColors.success : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 16),
                        _mediaBadge(
                          Icons.videocam_outlined,
                          hasVideo ? 'Video configurado' : 'Sin video',
                          hasVideo ? AppColors.success : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune, size: 20, color: AppColors.primary),
                    onPressed: () => _showMultimediaConfig(context, loc, settings),
                    tooltip: 'Configurar multimedia',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showEditDialog(context, loc, areaProvider, settings),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    onPressed: () => _confirmDelete(context, loc, settings),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPreview(KioskoMedia loc) {
    if (loc.logoUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.document_scanner_outlined, size: 28, color: AppColors.textSecondary),
      );
    }

    if (AreaLogoPreset.isPreset(loc.logoUrl)) {
      final parsed = AreaLogoPreset.parse(loc.logoUrl);
      if (parsed != null) {
        final preset = presetLogos.where((p) => p.id == parsed.$1).firstOrNull;
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: parsed.$2.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(preset?.icon ?? Icons.business, size: 28, color: parsed.$2),
        );
      }
    }

    final provider = safeImageProvider(loc.logoUrl);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
        color: provider == null ? Colors.grey[100] : null,
      ),
      child: provider == null
          ? const Icon(Icons.broken_image, size: 28, color: AppColors.textSecondary)
          : null,
    );
  }

  Widget _mediaBadge(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  void _showKioskoDetail(BuildContext context, KioskoMedia loc, AreaProvider areaProvider, SettingsProvider settings) {
    final areaNames = loc.areaIds.map((id) {
      final a = areaProvider.areaById(id);
      return a;
    }).whereType<Object>().toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            _buildLogoPreview(loc),
            const SizedBox(width: 16),
            Expanded(child: Text(loc.nombre, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loc.videoUrl.isNotEmpty) ...[
                  const Text('Video de fondo:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(loc.videoUrl, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Áreas asignadas:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                if (loc.areaIds.isEmpty)
                  const Text('Ninguna', style: TextStyle(color: AppColors.textSecondary))
                else
                  ...loc.areaIds.map((id) {
                    final a = areaProvider.areaById(id);
                    if (a == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.business, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('${a.nombre} (${a.prefijo ?? ""})', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Estado:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (loc.id == settings.selectedKioskoId ? AppColors.success : Colors.grey).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loc.id == settings.selectedKioskoId ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 12,
                          color: loc.id == settings.selectedKioskoId ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (loc.id != settings.selectedKioskoId)
                      TextButton.icon(
                        onPressed: () {
                          settings.setSelectedKioskoId(loc.id,
                            areaIds: loc.areaIds.toList(),
                            logoUrl: loc.logoUrl,
                            videoUrl: loc.videoUrl,
                            nombre: loc.nombre);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Activar kiosko', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showMultimediaConfig(context, loc, settings);
            },
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Configurar multimedia'),
          ),
        ],
      ),
    );
  }

  void _showMultimediaConfig(BuildContext context, KioskoMedia loc, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => _MultimediaConfigDialog(kiosko: loc, settings: settings),
    );
  }

  void _showEditDialog(BuildContext context, KioskoMedia? existing, AreaProvider areaProvider, SettingsProvider settings) {
    final nameCtrl = TextEditingController(text: existing?.nombre ?? '');
    final selectedAreaIds = Set<int>.from(existing?.areaIds ?? {});

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allAreas = areaProvider.areas;

            return AlertDialog(
              title: Text(existing != null ? 'Editar Kiosko' : 'Nuevo Kiosko'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Kiosko',
                        hintText: 'Ej: Kiosco Principal',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Áreas asignadas:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (allAreas.isEmpty)
                      const Text('No hay áreas disponibles', style: TextStyle(color: AppColors.textSecondary))
                    else
                      SizedBox(
                        height: 200,
                        child: ListView(
                          children: allAreas.map((area) {
                            final isSelected = selectedAreaIds.contains(area.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (v) {
                                setDialogState(() {
                                  if (v == true) {
                                    selectedAreaIds.add(area.id);
                                  } else {
                                    selectedAreaIds.remove(area.id);
                                  }
                                });
                              },
                              title: Text(area.nombre, style: const TextStyle(fontSize: 14)),
                              subtitle: Text(area.prefijo ?? '', style: const TextStyle(fontSize: 11)),
                              dense: true,
                              controlAffinity: ListTileControlAffinity.trailing,
                              contentPadding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    if (existing != null) {
                      await settings.updateKioskoMedia(existing.copyWith(
                        nombre: name,
                        areaIds: Set.from(selectedAreaIds),
                      ));
                    } else {
                      final maxId = settings.kioskoLocations.isEmpty
                          ? 0
                          : settings.kioskoLocations.map((k) => k.id).reduce((a, b) => a > b ? a : b);
                      await settings.addKioskoMedia(KioskoMedia(
                        id: maxId + 1,
                        nombre: name,
                        areaIds: Set.from(selectedAreaIds),
                      ));
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, KioskoMedia loc, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Kiosko'),
        content: Text('¿Eliminar "${loc.nombre}"? Se perderá toda su configuración multimedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.deleteKioskoMedia(loc.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MultimediaConfigDialog extends StatefulWidget {
  final KioskoMedia kiosko;
  final SettingsProvider settings;

  const _MultimediaConfigDialog({required this.kiosko, required this.settings});

  @override
  State<_MultimediaConfigDialog> createState() => _MultimediaConfigDialogState();
}

class _MultimediaConfigDialogState extends State<_MultimediaConfigDialog> {
  late TextEditingController _logoUrlCtrl;
  late TextEditingController _videoUrlCtrl;

  @override
  void initState() {
    super.initState();
    _logoUrlCtrl = TextEditingController(text: widget.kiosko.logoUrl);
    _videoUrlCtrl = TextEditingController(text: widget.kiosko.videoUrl);
  }

  @override
  void dispose() {
    _logoUrlCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      _logoUrlCtrl.text = result.files.single.path!;
      setState(() {});
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      _videoUrlCtrl.text = result.files.single.path!;
      setState(() {});
    }
  }

  void _selectPresetLogo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar icono'),
        content: SizedBox(
          width: 320,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: presetLogos.length,
            itemBuilder: (_, i) {
              final preset = presetLogos[i];
              final isSelected = _logoUrlCtrl.text == preset.storageKey;
              return GestureDetector(
                onTap: () {
                  _logoUrlCtrl.text = preset.storageKey;
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? preset.color.withValues(alpha: 0.15) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: preset.color, width: 2) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(preset.icon, size: 24, color: preset.color),
                      const SizedBox(height: 4),
                      Text(preset.label, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))],
      ),
    );
  }

  Future<void> _save() async {
    await widget.settings.updateKioskoMultimedia(
      widget.kiosko.id,
      logoUrl: _logoUrlCtrl.text.isNotEmpty ? _logoUrlCtrl.text : null,
      videoUrl: _videoUrlCtrl.text.isNotEmpty ? _videoUrlCtrl.text : null,
      clearLogo: _logoUrlCtrl.text.isEmpty,
      clearVideo: _videoUrlCtrl.text.isEmpty,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Multimedia: ${widget.kiosko.nombre}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Logo del Kiosko', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLogoPreviewWidget(_logoUrlCtrl.text),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _logoUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL o ruta del logo',
                        hintText: 'ruta/local/logo.png o URL',
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: const Text('Examinar', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _selectPresetLogo,
                    icon: const Icon(Icons.grid_view, size: 16),
                    label: const Text('Icono prediseñado', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  if (_logoUrlCtrl.text.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () {
                        _logoUrlCtrl.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Quitar', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Video de Fondo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _videoUrlCtrl.text.isNotEmpty ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _videoUrlCtrl.text.isNotEmpty
                        ? const Icon(Icons.play_circle, size: 28, color: Colors.white54)
                        : const Icon(Icons.videocam, size: 28, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _videoUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL o ruta del video',
                        hintText: 'C:\\videos\\promo.mp4 o URL',
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: const Text('Examinar video', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  if (_videoUrlCtrl.text.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () {
                        _videoUrlCtrl.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Quitar', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Formatos: PNG, JPG, ICO (logo) | MP4, AVI, MOV (video)',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar configuración'),
        ),
      ],
    );
  }

  Widget _buildLogoPreviewWidget(String url) {
    if (url.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_outlined, size: 28, color: AppColors.textSecondary),
      );
    }

    if (AreaLogoPreset.isPreset(url)) {
      final parsed = AreaLogoPreset.parse(url);
      if (parsed != null) {
        final preset = presetLogos.where((p) => p.id == parsed.$1).firstOrNull;
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: parsed.$2.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(preset?.icon ?? Icons.business, size: 28, color: parsed.$2),
        );
      }
    }

    final provider = safeImageProvider(url);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
        color: provider == null ? Colors.grey[100] : null,
      ),
      child: provider == null
          ? const Icon(Icons.broken_image, size: 28, color: AppColors.textSecondary)
          : null,
    );
  }
}
