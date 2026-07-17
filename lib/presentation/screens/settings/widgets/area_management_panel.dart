import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/area_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/user_management_provider.dart';
import '../../../../domain/entities/area.dart';
import '../../../../domain/entities/puesto_info.dart';
import '../../../../domain/entities/service_type.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/area_logo_presets.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class AreaManagementPanel extends StatefulWidget {
  const AreaManagementPanel({super.key});

  @override
  State<AreaManagementPanel> createState() => _AreaManagementPanelState();
}

class _AreaManagementPanelState extends State<AreaManagementPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AreaProvider>(context, listen: false).loadAreas();
    });
  }

  void _showAreaForm({Area? area}) {
    showDialog(
      context: context,
      builder: (ctx) => _AreaFormDialog(area: area),
    );
  }

  List<dynamic> _usersForArea(int areaId) {
    try {
      final userProvider = Provider.of<UserManagementProvider>(context, listen: false);
      return userProvider.activeUsers.where((u) =>
          (u.areasAtencion is List && u.areasAtencion.contains(areaId)) || u.areaId == areaId).toList();
    } catch (_) {
      return [];
    }
  }

  void _showAreaUsers(Area area) {
    final users = _usersForArea(area.id);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Usuarios de ${area.nombre}'),
        content: SizedBox(
          width: 360,
          child: users.isEmpty
              ? const Text('No hay usuarios asignados a esta área.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: u.activo ? AppColors.success : Colors.grey,
                        child: Text(u.nombreCompleto[0],
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      title: Text(u.nombreCompleto, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(u.email.isNotEmpty ? u.email : _roleName(u.rol),
                          style: const TextStyle(fontSize: 11)),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  void _showPuestoLayout(Area area) {
    showDialog(
      context: context,
      builder: (ctx) => _PuestoLayoutDialog(areaId: area.id, areaNombre: area.nombre),
    );
  }

  void _showServiceTypes(Area area) {
    showDialog(
      context: context,
      builder: (ctx) => _ServiceTypeDialog(areaId: area.id, areaNombre: area.nombre),
    );
  }

  Future<void> _confirmDelete(Area area) async {
    final provider = Provider.of<AreaProvider>(context, listen: false);
    final errorMsg = provider.deleteAreaError(area.id);

    if (errorMsg != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
          title: const Text('No se puede eliminar'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showAreaUsers(area);
              },
              child: const Text('Ver usuarios asignados'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar área'),
        content: Text('Eliminar "${area.nombre}" (${area.prefijo})?\nLos tickets asociados no se verán afectados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await provider.deleteArea(area.id);
      if (success) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        await settings.removePuestosForArea(area.id);
        await settings.removeServiceTypesForArea(area.id);
      }
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al eliminar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gestión de Áreas', style: Theme.of(context).textTheme.headlineSmall),
              ElevatedButton.icon(
                onPressed: () => _showAreaForm(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Área'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<AreaProvider>(
              builder: (context, areaProvider, _) {
                if (areaProvider.areas.isEmpty) {
                  return const Center(child: Text('No hay áreas registradas'));
                }
                return ListView.builder(
                  itemCount: areaProvider.areas.length,
                  itemBuilder: (context, index) {
                    final area = areaProvider.areas[index];
                    final userCount = _usersForArea(area.id).length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: _buildAreaLogo(area),
                        title: Row(
                          children: [
                            Text(area.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (!area.activo)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Inactivo', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ),
                          ],
                        ),
                        subtitle: Text('Prefijo: ${area.prefijo}  ·  $userCount usuario${userCount == 1 ? '' : 's'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.people, size: 20),
                              tooltip: 'Ver usuarios asignados',
                              onPressed: () => _showAreaUsers(area),
                            ),
                            IconButton(
                              icon: const Icon(Icons.meeting_room_outlined, size: 20),
                              tooltip: 'Puestos físicos',
                              onPressed: () => _showPuestoLayout(area),
                            ),
                            IconButton(
                              icon: const Icon(Icons.category_outlined, size: 20),
                              tooltip: 'Servicios del área',
                              onPressed: () => _showServiceTypes(area),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showAreaForm(area: area),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () => _confirmDelete(area),
                            ),
                          ],
                        ),
                        onTap: () => _showAreaUsers(area),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaLogo(Area area) {
    if (area.logoUrl.isNotEmpty) {
      if (AreaLogoPreset.isPreset(area.logoUrl)) {
        final parsed = AreaLogoPreset.parse(area.logoUrl);
        if (parsed != null) {
          final preset = presetLogos.where((p) => p.id == parsed.$1).firstOrNull;
          if (preset != null) {
            return CircleAvatar(
              radius: 22,
              backgroundColor: parsed.$2.withValues(alpha: 0.15),
              child: Icon(preset.icon, color: parsed.$2, size: 22),
            );
          }
        }
        return CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[200],
          child: Text(area.prefijo[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        );
      }
      return CircleAvatar(
        radius: 22,
        backgroundImage: safeImageProvider(area.logoUrl),
        backgroundColor: Colors.grey[200],
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: area.activo ? AppColors.primary : Colors.grey,
      child: Text(area.prefijo[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  String _roleName(UserRole rol) {
    return rol.displayName;
  }
}

class _AreaFormDialog extends StatefulWidget {
  final Area? area;
  const _AreaFormDialog({this.area});

  @override
  State<_AreaFormDialog> createState() => _AreaFormDialogState();
}

class _AreaFormDialogState extends State<_AreaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _prefijoCtrl;
  String _logoUrl = '';
  bool _isSaving = false;
  int _logoTab = 0; // 0: preset, 1: file upload

  @override
  void initState() {
    super.initState();
    final a = widget.area;
    _nameCtrl = TextEditingController(text: a?.nombre ?? '');
    _prefijoCtrl = TextEditingController(text: a?.prefijo ?? '');
    _logoUrl = a?.logoUrl ?? '';
    if (_logoUrl.isNotEmpty && !AreaLogoPreset.isPreset(_logoUrl)) {
      _logoTab = 1;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _prefijoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'svg'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _logoUrl = result.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.area != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar Área' : 'Nueva Área'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del área',
                    hintText: 'Ej: Caja, Información',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _prefijoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prefijo',
                    hintText: 'Ej: CAJA, INFO',
                    border: OutlineInputBorder(),
                    helperText: '2-6 letras, se usará en el código del ticket (CAJA-001)',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                    if (v.trim().length > 6) return 'Máximo 6 caracteres';
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text('Logo del área',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const Spacer(),
                    SizedBox(
                      height: 28,
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Ícono', style: TextStyle(fontSize: 11)), icon: Icon(Icons.emoji_symbols, size: 14)),
                          ButtonSegment(value: 1, label: Text('Archivo', style: TextStyle(fontSize: 11)), icon: Icon(Icons.cloud_upload, size: 14)),
                        ],
                        selected: {_logoTab},
                        onSelectionChanged: (v) => setState(() {
                          _logoTab = v.first;
                          if (_logoTab == 0 && AreaLogoPreset.isPreset(_logoUrl) == false) {
                            _logoUrl = '';
                          }
                        }),
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_logoTab == 0)
                  _buildPresetGrid()
                else
                  _buildFileUploadSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  Widget _buildPresetGrid() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text('Seleccioná un ícono para representar el área',
                      style: TextStyle(fontSize: 11, color: Colors.blue[800])),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: presetLogos.length,
            itemBuilder: (_, i) {
              final preset = presetLogos[i];
              final selected = _logoUrl == preset.storageKey;
              return Material(
                color: selected ? preset.color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _logoUrl = preset.storageKey),
                  child: Container(
                    decoration: selected
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: preset.color, width: 2),
                          )
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(preset.icon, color: preset.color, size: 26),
                        const SizedBox(height: 4),
                        Text(preset.label,
                            style: TextStyle(fontSize: 9, color: preset.color),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text('Recomendaciones del logo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue[700])),
                ],
              ),
              const SizedBox(height: 6),
              _legendItem('Formato: PNG, JPG o SVG'),
              _legendItem('Tamaño: 200x200 px mínimo'),
              _legendItem('Fondo: transparente o blanco'),
              _legendItem('Peso: máximo 1 MB'),
              _legendItem('Se mostrará en un círculo de 44px'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.cloud_upload, size: 18),
                label: Text(_logoUrl.isNotEmpty && !AreaLogoPreset.isPreset(_logoUrl)
                    ? 'Cambiar logo'
                    : 'Subir logo'),
              ),
            ),
            if (_logoUrl.isNotEmpty && !AreaLogoPreset.isPreset(_logoUrl)) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _logoUrl = ''),
              ),
            ],
          ],
        ),
        if (_logoUrl.isNotEmpty && !AreaLogoPreset.isPreset(_logoUrl)) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: safeImageProvider(_logoUrl),
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _logoUrl.split('/').last,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _legendItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 12, color: Colors.blue[400]),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.blue[800])),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = Provider.of<AreaProvider>(context, listen: false);
    final a = widget.area;

    bool success;
    if (a != null) {
      success = await provider.updateArea(
        id: a.id,
        nombre: _nameCtrl.text.trim(),
        prefijo: _prefijoCtrl.text.trim(),
        activo: a.activo,
        logoUrl: _logoUrl,
      );
    } else {
      success = await provider.createArea(
        nombre: _nameCtrl.text.trim(),
        prefijo: _prefijoCtrl.text.trim(),
        logoUrl: _logoUrl,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (a != null ? 'Área actualizada' : 'Área creada')
              : 'Error: ${provider.errorMessage ?? "desconocido"}'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }
}

class _PuestoLayoutDialog extends StatefulWidget {
  final int areaId;
  final String areaNombre;
  const _PuestoLayoutDialog({required this.areaId, required this.areaNombre});

  @override
  State<_PuestoLayoutDialog> createState() => _PuestoLayoutDialogState();
}

class _PuestoLayoutDialogState extends State<_PuestoLayoutDialog> {
  late List<PuestoInfo> _puestos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPuestos();
  }

  Future<void> _loadPuestos() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final response = await api.get(ApiConstants.puestosByArea(widget.areaId));
      final list = (response.data as List?) ?? [];
      _puestos = list.map((e) {
        final m = e as Map<String, dynamic>;
        return PuestoInfo(
          id: m['id'] as int,
          nombre: m['nombre'] as String? ?? '',
          occupiedByUserId: (m['ocupado'] as bool?) == true ? -1 : null,
        );
      }).toList();
    } catch (_) {
      _puestos = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _add() {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Nuevo puesto'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre del puesto',
              hintText: 'Ej: Caja 1, Mesa 3',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                try {
                  final api = Provider.of<ApiClient>(context, listen: false);
                  final response = await api.post(
                    ApiConstants.puestosByArea(widget.areaId),
                    data: {'nombre': name},
                  );
                  final m = response.data as Map<String, dynamic>;
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {
                    _puestos.add(PuestoInfo(
                      id: m['id'] as int,
                      nombre: m['nombre'] as String? ?? name,
                    ));
                  });
                } catch (_) {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _delete(PuestoInfo puesto) async {
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      await api.delete('${ApiConstants.puestosByArea(widget.areaId)}/${puesto.id}');
      setState(() => _puestos.removeWhere((p) => p.id == puesto.id));
    } catch (_) {}
  }

  Widget _buildPuestoCard(PuestoInfo p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.meeting_room_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(p.nombre, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            if (p.occupiedByUserId != null && p.occupiedByUserId! > 0)
              const Icon(Icons.lock, size: 18, color: Colors.orange)
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                onPressed: () => _delete(p),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Puestos de ${widget.areaNombre}'),
      content: SizedBox(
        width: 360,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Puestos físicos:', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isLoading ? null : _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _puestos.isEmpty
                      ? const Center(child: Text('Sin puestos configurados'))
                      : SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in _puestos)
                                _buildPuestoCard(p),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}

class _ServiceTypeDialog extends StatefulWidget {
  final int areaId;
  final String areaNombre;
  const _ServiceTypeDialog({required this.areaId, required this.areaNombre});

  @override
  State<_ServiceTypeDialog> createState() => _ServiceTypeDialogState();
}

class _ServiceTypeDialogState extends State<_ServiceTypeDialog> {
  late List<ServiceType> _types;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final response = await api.get(ApiConstants.serviciosByArea(widget.areaId));
      final list = (response.data as List?) ?? [];
      _types = list.map((e) {
        final m = e as Map<String, dynamic>;
        return ServiceType(
          id: m['id'] as int,
          areaId: widget.areaId,
          nombre: m['nombre'] as String? ?? '',
          iconName: m['icono'] as String? ?? 'help_outline',
        );
      }).toList();
    } catch (_) {
      _types = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _add() {
    final nameCtrl = TextEditingController();
    String selectedIcon = 'help_outline';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo servicio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del servicio',
                      hintText: 'Ej: Pago, Consulta, Recepción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedIcon,
                    decoration: const InputDecoration(
                      labelText: 'Icono',
                      border: OutlineInputBorder(),
                    ),
                    items: ServiceType.iconOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt['icon'] as String,
                        child: Row(
                          children: [
                            Icon(_iconFromName(opt['icon'] as String), size: 20),
                            const SizedBox(width: 8),
                            Text(opt['name'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedIcon = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    try {
                      final api = Provider.of<ApiClient>(context, listen: false);
                      final response = await api.post(
                        ApiConstants.serviciosByArea(widget.areaId),
                        data: {'nombre': name, 'icono': selectedIcon},
                      );
                      final m = response.data as Map<String, dynamic>;
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(() {
                        _types.add(ServiceType(
                          id: m['id'] as int,
                          areaId: widget.areaId,
                          nombre: m['nombre'] as String? ?? name,
                          iconName: m['icono'] as String? ?? selectedIcon,
                        ));
                      });
                    } catch (_) {
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _delete(ServiceType t) async {
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      await api.delete('${ApiConstants.serviciosByArea(widget.areaId)}/${t.id}');
      setState(() => _types.removeWhere((x) => x.id == t.id));
    } catch (_) {}
  }

  IconData _iconFromName(String name) {
    final entry = ServiceType.iconOptions.firstWhere(
      (o) => o['icon'] == name,
      orElse: () => {'icon': 'help_outline'},
    );
    return ServiceType.iconByName(entry['icon'] as String);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Servicios de ${widget.areaNombre}'),
      content: SizedBox(
        width: 360,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                const Text('Tipos de servicio:', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isLoading ? null : _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _types.isEmpty
                      ? const Center(child: Text('Sin servicios configurados'))
                      : ListView.builder(
                          itemCount: _types.length,
                          itemBuilder: (_, i) {
                            final t = _types[i];
                            return ListTile(
                              dense: true,
                              leading: Icon(t.icon, color: AppColors.primary, size: 22),
                              title: Text(t.nombre, style: const TextStyle(fontSize: 14)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () => _delete(t),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}
