import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_management_provider.dart';
import '../../../providers/area_provider.dart';
import '../../../../domain/entities/user.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';

class UserManagementPanel extends StatefulWidget {
  const UserManagementPanel({super.key});

  @override
  State<UserManagementPanel> createState() => _UserManagementPanelState();
}

class _UserManagementPanelState extends State<UserManagementPanel> {
  String _searchQuery = '';
  final Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserManagementProvider>(context, listen: false).loadUsers();
    });
  }

  void _showUserForm({User? user, String? preSelectedRol, List<int>? preSelectedAreas}) {
    showDialog(
      context: context,
      builder: (ctx) => _UserFormDialog(
        user: user,
        preSelectedRol: preSelectedRol,
        preSelectedAreas: preSelectedAreas,
      ),
    );
  }

  Future<void> _confirmDelete(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('Eliminar a "${user.nombreCompleto}"?\nLos tickets asociados no se veran afectados.'),
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
      await Provider.of<UserManagementProvider>(context, listen: false).deleteUser(user.id);
    }
  }

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
              Text('Gestion de Usuarios',
                  style: Theme.of(context).textTheme.headlineSmall),
              ElevatedButton.icon(
                onPressed: () => _showUserForm(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, area o correo...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<UserManagementProvider>(
              builder: (context, provider, _) {
                final allUsers = provider.users;
                if (allUsers.isEmpty) {
                  return const Center(child: Text('No hay usuarios registrados'));
                }

                final filtered = _searchQuery.isEmpty
                    ? allUsers
                    : allUsers.where((u) {
                        final q = _searchQuery;
                        final areasStr = u.areasAtencion
                            .map((id) => _getAreaName(id).toLowerCase())
                            .join(' ');
                        return u.nombreCompleto.toLowerCase().contains(q) ||
                            u.nombreUsuario.toLowerCase().contains(q) ||
                            u.email.toLowerCase().contains(q) ||
                            areasStr.contains(q) ||
                            _roleName(u.rol).toLowerCase().contains(q);
                      }).toList();

                final grouped = <String, List<User>>{};
                for (final u in filtered) {
                  final key = _groupKey(u);
                  grouped.putIfAbsent(key, () => []).add(u);
                }
                final sortedKeys = grouped.keys.toList()
                  ..sort((a, b) {
                    if (a == 'Administradores') return -1;
                    if (b == 'Administradores') return 1;
                    if (a == 'Supervisores') return -1;
                    if (b == 'Supervisores') return 1;
                    if (a == 'Llamadores') return -1;
                    if (b == 'Llamadores') return 1;
                    if (a == 'Operadores') return -1;
                    if (b == 'Operadores') return 1;
                    return a.compareTo(b);
                  });

                if (_expandedGroups.isEmpty && sortedKeys.isNotEmpty) {
                  _expandedGroups.addAll(sortedKeys);
                }

                return ListView(
                  children: [
                    for (final key in sortedKeys) ...[
                      _buildGroupTile(key, grouped[key]!, provider),
                    ],
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text('Sin resultados para "$_searchQuery"',
                              style: TextStyle(color: Colors.grey[400])),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(String groupName, List<User> users, UserManagementProvider provider) {
    final isExpanded = _expandedGroups.contains(groupName);
    final count = users.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedGroups.remove(groupName);
              } else {
                _expandedGroups.add(groupName);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(groupName,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700])),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.person_add, size: 18),
                      tooltip: 'Agregar usuario a este grupo',
                      color: AppColors.primary,
                      onPressed: () {
                        final (rol, areas) = _prefillForGroup(groupName);
                        _showUserForm(preSelectedRol: rol, preSelectedAreas: areas);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: Colors.grey[200]),
                ...users.map((u) => _buildUserCard(u, provider)),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  (String?, List<int>?) _prefillForGroup(String groupName) {
    if (groupName == 'Administradores') return ('administrador', null);
    if (groupName == 'Llamadores') return ('llamador', null);
    if (groupName == 'Supervisores') return ('supervisor', null);
    if (groupName == 'Operadores') return ('operador', null);
    if (groupName == 'Multi-area' || groupName == 'Usuarios sin area') return (null, null);
    try {
      final area = Provider.of<AreaProvider>(context, listen: false)
          .areas
          .firstWhere((a) => a.nombre == groupName);
      return ('operador', [area.id]);
    } catch (_) {
      return (null, null);
    }
  }

  Widget _buildUserCard(User u, UserManagementProvider provider) {
    final areasStr = u.rol == UserRole.operador && u.areasAtencion.isNotEmpty
        ? u.areasAtencion.map((id) => _getAreaName(id)).join(', ')
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: u.activo ? AppColors.success : Colors.grey,
            child: Text(u.nombreCompleto[0],
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(u.nombreCompleto, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (u.email.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.email_outlined, size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(u.email,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(areasStr.isNotEmpty ? '${_roleName(u.rol)} - $areasStr' : _roleName(u.rol),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _showUserForm(user: u),
          ),
          IconButton(
            icon: Icon(
              u.activo ? Icons.visibility : Icons.visibility_off,
              size: 18,
              color: u.activo ? null : Colors.grey,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => provider.toggleUserActive(u.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _confirmDelete(u),
          ),
        ],
      ),
    );
  }

  String _groupKey(User u) {
    if (u.rol == UserRole.administrador) return 'Administradores';
    if (u.rol == UserRole.supervisor) return 'Supervisores';
    if (u.rol == UserRole.llamador) return 'Llamadores';
    if (u.rol == UserRole.operador) return 'Operadores';
    final areas = u.areasAtencion
        .map((id) => _getAreaName(id))
        .where((n) => n.isNotEmpty)
        .toList();
    if (areas.isEmpty) return 'Usuarios sin area';
    if (areas.length == 1) return areas.first;
    return 'Multi-area';
  }

  String _roleName(UserRole rol) {
    return rol.displayName;
  }

  String _getAreaName(int areaId) {
    try {
      return Provider.of<AreaProvider>(context, listen: false)
          .areas
          .firstWhere((a) => a.id == areaId)
          .nombre;
    } catch (_) {
      return 'Area #$areaId';
    }
  }
}

class _UserFormDialog extends StatefulWidget {
  final User? user;
  final String? preSelectedRol;
  final List<int>? preSelectedAreas;

  const _UserFormDialog({this.user, this.preSelectedRol, this.preSelectedAreas});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late String _selectedRol;
  late List<int> _selectedAreas;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _usernameCtrl = TextEditingController(text: u?.nombreUsuario ?? '');
    _nameCtrl = TextEditingController(text: u?.nombreCompleto ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _passwordCtrl = TextEditingController();
    _selectedRol = u?.rol.apiValue ?? widget.preSelectedRol ?? 'operador';
    _selectedAreas = List.from(u?.areasAtencion ?? widget.preSelectedAreas ?? []);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final areas = Provider.of<AreaProvider>(context).areas.where((a) => a.activo).toList();

    return AlertDialog(
      title: Text(isEdit ? 'Editar Usuario' : 'Nuevo Usuario'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  enabled: !isEdit,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo electronico',
                    hintText: 'usuario@ejemplo.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                if (!isEdit)
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contrasena',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (isEdit) return null;
                      return (v == null || v.trim().isEmpty) ? 'Requerido' : null;
                    },
                    obscureText: true,
                  ),
                if (!isEdit) const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedRol,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'administrador', child: Text('Administrador')),
                    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                    DropdownMenuItem(value: 'operador', child: Text('Operador')),
                    DropdownMenuItem(value: 'llamador', child: Text('Llamador')),
                  ],
                  onChanged: (v) => setState(() {
                    _selectedRol = v ?? 'operador';
                    if (_selectedRol != 'operador') _selectedAreas = [];
                  }),
                ),
                const SizedBox(height: 14),
                if (_selectedRol == 'operador') ...[
                  const SizedBox(height: 14),
                  const Text('Areas de atencion:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  ...areas.map((area) => CheckboxListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        value: _selectedAreas.contains(area.id),
                        title: Text('${area.nombre} (${area.prefijo})',
                            style: const TextStyle(fontSize: 14)),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedAreas.add(area.id);
                            } else {
                              _selectedAreas.remove(area.id);
                            }
                          });
                        },
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRol == 'operador' && _selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos un área para el operador'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = Provider.of<UserManagementProvider>(context, listen: false);
    bool success;
    final u = widget.user;
    final areaId = _selectedAreas.isNotEmpty ? _selectedAreas.first : null;

    if (u != null) {
      final updated = u.copyWith(
        nombreCompleto: _nameCtrl.text.trim(),
        rol: UserRole.fromApiValue(_selectedRol),
        areaId: areaId,
        activo: u.activo,
        areasAtencion: _selectedAreas,
      );
      success = await provider.updateUser(updated, areasAtencion: _selectedAreas);
    } else {
      success = await provider.createUser(
        nombreUsuario: _usernameCtrl.text.trim(),
        nombreCompleto: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        rol: _selectedRol,
        areaId: areaId,
        areasAtencion: _selectedAreas,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (u != null ? 'Usuario actualizado' : 'Usuario creado')
              : 'Error: ${provider.errorMessage ?? "desconocido"}'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }

  String _getAreaName(int areaId) {
    try {
      return Provider.of<AreaProvider>(context, listen: false)
          .areas
          .firstWhere((a) => a.id == areaId)
          .nombre;
    } catch (_) {
      return 'Area #$areaId';
    }
  }
}
