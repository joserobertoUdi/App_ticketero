import 'package:flutter/material.dart';

import '../../../core/cache/data_store.dart';
import '../../../core/cache/models/cached_user.dart';
import '../../../core/theme/app_colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Panel de Pruebas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Usuarios', icon: Icon(Icons.people)),
            Tab(text: 'Simular Tickets', icon: Icon(Icons.play_arrow)),
            Tab(text: 'Ver Flujo', icon: Icon(Icons.visibility)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Resetear datos',
            onPressed: () {
              DataStore.instance.reset();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos restablecidos')),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserManagementTab(onChanged: () => setState(() {})),
          _SimulationTab(onChanged: () => setState(() {})),
          _FlowViewerTab(),
        ],
      ),
    );
  }
}

class _UserManagementTab extends StatefulWidget {
  final VoidCallback onChanged;
  const _UserManagementTab({required this.onChanged});
  @override
  State<_UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<_UserManagementTab> {
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedRol = 'operador';
  int? _selectedAreaId;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _addUser() {
    final u = _usernameCtrl.text.trim();
    final n = _nameCtrl.text.trim();
    final p = _passCtrl.text.trim();
    if (u.isEmpty || n.isEmpty || p.isEmpty) return;

    final area = _selectedAreaId != null
        ? DataStore.instance.areas.firstWhere((a) => a.id == _selectedAreaId)
        : null;

    DataStore.instance.addUser(CachedUser(
      id: DataStore.instance.nextUserId,
      nombreUsuario: u,
      nombreCompleto: n,
      password: p,
      rol: _selectedRol,
      areaId: area?.id,
      areaNombre: area?.nombre,
    ));

    _usernameCtrl.clear();
    _nameCtrl.clear();
    _passCtrl.clear();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = DataStore.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usuarios Existentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...store.users.map((u) => Card(
            child: ListTile(
              leading: Icon(_iconForRol(u.rol), color: AppColors.primary),
              title: Text('${u.nombreCompleto} (@${u.nombreUsuario})'),
              subtitle: Text('Rol: ${u.rol} | Área: ${u.areaNombre ?? "-"}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  store.deleteUser(u.id);
                  widget.onChanged();
                  setState(() {});
                },
              ),
            ),
          )),
          const SizedBox(height: 24),
          const Text('Agregar Usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Usuario', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()), obscureText: true),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedRol,
            decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'administrador', child: Text('Administrador')),
              DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
              DropdownMenuItem(value: 'operador', child: Text('Operador')),
              DropdownMenuItem(value: 'llamador', child: Text('Llamador')),
            ],
            onChanged: (v) => setState(() => _selectedRol = v!),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            initialValue: _selectedAreaId,
            decoration: const InputDecoration(labelText: 'Área', border: OutlineInputBorder()),
            items: store.areas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre))).toList(),
            onChanged: (v) => setState(() => _selectedAreaId = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addUser,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Usuario'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  IconData _iconForRol(String rol) {
    switch (rol) {
      case 'administrador': return Icons.admin_panel_settings;
      case 'supervisor': return Icons.supervisor_account;
      case 'llamador': return Icons.campaign;
      default: return Icons.headset_mic;
    }
  }
}

class _SimulationTab extends StatefulWidget {
  final VoidCallback onChanged;
  const _SimulationTab({required this.onChanged});
  @override
  State<_SimulationTab> createState() => _SimulationTabState();
}

class _SimulationTabState extends State<_SimulationTab> {
  @override
  Widget build(BuildContext context) {
    final store = DataStore.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Generar Tickets de Prueba', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Crea tickets para probar el flujo:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ...store.areas.where((a) => a.activo).map((area) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  store.createTicket(area.id, area.prefijo, area.nombre, 'consulta');
                  widget.onChanged();
                  setState(() {});
                },
                icon: const Icon(Icons.add),
                label: Text('Ticket para ${area.nombre}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          )),
          const SizedBox(height: 24),
          const Text('Tickets Pendientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...store.pendingTickets.map((t) => Card(
            child: ListTile(
              title: Text('${t.codigo} - ${t.areaNombre}'),
              subtitle: Text('Creado: ${_fmt(t.creado)}'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  store.callNextTicket(1);
                  widget.onChanged();
                  setState(() {});
                },
                child: const Text('Llamar'),
              ),
            ),
          )),
          if (store.pendingTickets.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No hay tickets pendientes', style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 24),
          const Text('Tickets Llamados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...store.calledTickets.map((t) => Card(
            child: ListTile(
              title: Text('${t.codigo} - ${t.areaNombre}'),
              subtitle: Text('Llamado: ${_fmt(t.llamadoEn)}'),
              leading: const Icon(Icons.check_circle, color: Colors.green),
            ),
          )),
          if (store.calledTickets.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No hay tickets llamados', style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 24),
          const Text('Acciones Rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                for (final a in store.areas.where((a) => a.activo)) {
                  store.createTicket(a.id, a.prefijo, a.nombre, 'consulta');
                }
                widget.onChanged();
                setState(() {});
              },
              icon: const Icon(Icons.playlist_add),
              label: const Text('Generar 1 ticket por cada área'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final user = store.getUserByUsername('llamador');
                if (user != null) {
                  for (int i = 0; i < 5; i++) {
                    final area = store.activeAreas[i % store.activeAreas.length];
                  store.createTicket(area.id, area.prefijo, area.nombre, 'consulta');
                  }
                  widget.onChanged();
                  setState(() {});
                }
              },
              icon: const Icon(Icons.movie),
              label: const Text('Generar 5 tickets mock'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

class _FlowViewerTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = DataStore.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Flujo de Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Simulación visual del estado de los tickets:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          if (store.tickets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Genera tickets en "Simular Tickets" para ver el flujo',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            )
          else
            ...store.tickets.take(10).map((t) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.estado == 'pendiente'
                            ? Colors.orange.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        t.estado == 'pendiente' ? Icons.hourglass_empty : Icons.check_circle,
                        color: t.estado == 'pendiente' ? Colors.orange : Colors.green,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.codigo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(t.areaNombre, style: TextStyle(color: Colors.grey[600])),
                          Text('Estado: ${t.estado}', style: TextStyle(color: t.estado == 'pendiente' ? Colors.orange : Colors.green, fontWeight: FontWeight.w500)),
                          Text('Creado: ${_fmt(t.creado)}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                    ),
                    if (t.llamadoEn != null)
                      Chip(
                        label: Text('Llamado ${_fmt(t.llamadoEn)}', style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                      ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
