import 'package:flutter/material.dart';

import '../../layout/app_shell.dart';
import '../../layout/topbar.dart';

class GestionScreen extends StatefulWidget {
  const GestionScreen({super.key});

  @override
  State<GestionScreen> createState() => _GestionScreenState();
}

class _GestionScreenState extends State<GestionScreen> {
  String _tab = 'operadores';

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Gestión',
      subtitle: 'Administración de ventanillas y operadores',
      currentRoute: '/gestion',
      tabs: const [
        TabOption(label: 'Operadores', value: 'operadores'),
        TabOption(label: 'Usuarios', value: 'usuarios'),
      ],
      activeTab: _tab,
      onTabChanged: (v) => setState(() => _tab = v),
      body: _tab == 'operadores' ? _buildOperadores() : _buildUsuarios(),
    );
  }

  Widget _buildOperadores() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ventanillas activas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('${_operadores.length} operadores en línea',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                Expanded(child: _OperadoresTable(data: _operadores)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(flex: 3, child: _AddOperatorPanel()),
        ],
      ),
    );
  }

  Widget _buildUsuarios() {
    return const Center(
      child: Text('Gestión de usuarios', style: TextStyle(fontSize: 16, color: Colors.grey)),
    );
  }
}

class _OperatorInfo {
  final int ventanilla;
  final String area;
  final Color areaColor;
  final String operador;
  final String estado;
  final String? turno;
  const _OperatorInfo({required this.ventanilla, required this.area, required this.areaColor, required this.operador, required this.estado, this.turno});
}

const _operadores = <_OperatorInfo>[];

class _OperadoresTable extends StatelessWidget {
  final List<_OperatorInfo> data;
  const _OperadoresTable({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: const Row(
            children: [
              _Col(text: 'Nº', flex: 1),
              _Col(text: 'VENT.', flex: 2),
              _Col(text: 'ÁREA', flex: 2),
              _Col(text: 'OPERADOR', flex: 3),
              _Col(text: 'ESTADO', flex: 2),
              _Col(text: 'TURNO', flex: 2),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
            itemBuilder: (context, index) {
              final op = data[index];
              return Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: index.isEven ? Colors.white : const Color(0xFFF9FAFB),
                child: Row(
                  children: [
                    _Col(text: '#${op.ventanilla}', flex: 1, bold: true),
                    _Col(text: '${op.ventanilla}', flex: 2),
                    _AreaCol(label: op.area, color: op.areaColor, flex: 2),
                    _Col(text: op.operador, flex: 3),
                    _EstadoPill(estado: op.estado, flex: 2),
                    _Col(text: op.turno ?? '—', flex: 2, bold: op.turno != null),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Col extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  const _Col({required this.text, required this.flex, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: TextStyle(fontSize: bold ? 13 : 12, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: Colors.grey[800])),
    );
  }
}

class _AreaCol extends StatelessWidget {
  final String label;
  final Color color;
  final int flex;
  const _AreaCol({required this.label, required this.color, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _EstadoPill extends StatelessWidget {
  final String estado;
  final int flex;
  const _EstadoPill({required this.estado, required this.flex});

  Color get _color {
    switch (estado) {
      case 'Atendiendo': return const Color(0xFF22C55E);
      case 'Libre': return Colors.grey;
      case 'Pausa': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: Text('● $estado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _color)),
      ),
    );
  }
}

class _AddOperatorPanel extends StatefulWidget {
  @override
  State<_AddOperatorPanel> createState() => _AddOperatorPanelState();
}

class _AddOperatorPanelState extends State<_AddOperatorPanel> {
  int? _selectedVentanilla;
  int? _selectedArea;
  String? _selectedOperator;

  final _areas = [
    {'id': 1, 'name': 'Caja', 'color': const Color(0xFFE30613)},
    {'id': 2, 'name': 'Registro', 'color': const Color(0xFF1565C0)},
    {'id': 3, 'name': 'Marketing', 'color': const Color(0xFF7B1FA2)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, size: 20),
              const SizedBox(width: 8),
              const Text('Agregar operador', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Nº de ventanilla', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _selectedVentanilla,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(), isDense: true),
            items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('#${i + 1}'))),
            onChanged: (v) => setState(() => _selectedVentanilla = v),
          ),
          const SizedBox(height: 20),
          const Text('Área', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          ..._areas.map((area) {
            final isSelected = _selectedArea == area['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedArea = area['id'] as int),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFCEBEB) : Colors.transparent,
                  border: Border.all(color: isSelected ? const Color(0xFFE30613) : const Color(0xFFE5E7EB), width: isSelected ? 1.5 : 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: area['color'] as Color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text(area['name'] as String, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text('Asignar operador', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedOperator,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.chevron_right, size: 20)),
            hint: const Text('Seleccionar...'),
            items: const [
              DropdownMenuItem(value: 'ana', child: Text('Ana Pérez')),
              DropdownMenuItem(value: 'luis', child: Text('Luis García')),
              DropdownMenuItem(value: 'sofia', child: Text('Sofía Torres')),
            ],
            onChanged: (v) => setState(() => _selectedOperator = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE30613), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Guardar ventanilla', style: TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}
