import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';

class SystemConfigPanel extends StatefulWidget {
  const SystemConfigPanel({super.key});

  @override
  State<SystemConfigPanel> createState() => _SystemConfigPanelState();
}

class _SystemConfigPanelState extends State<SystemConfigPanel> {
  final _serverCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _ticketsCtrl = TextEditingController();
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final s = Provider.of<SettingsProvider>(context, listen: false);
    _serverCtrl.text = s.serverUrl;
    _timeCtrl.text = s.tiempoEstimadoMinutos.toString();
    _ticketsCtrl.text = s.maxTicketsPorDia.toString();
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _timeCtrl.dispose();
    _ticketsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final s = Provider.of<SettingsProvider>(context, listen: false);
    final url = _serverCtrl.text.trim();
    final time = int.tryParse(_timeCtrl.text.trim());
    final tickets = int.tryParse(_ticketsCtrl.text.trim());
    if (url.isNotEmpty) s.updateServerUrl(url);
    if (time != null && time > 0) s.updateTimeEstimate(time);
    if (tickets != null && tickets > 0) s.updateMaxTickets(tickets);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final url = _serverCtrl.text.trim();
      final dio = Dio();
      final response = await dio
          .get('$url/api/health')
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() => _testResult = 'Conexión exitosa ✓');
      } else {
        setState(() =>
            _testResult = 'Respuesta inesperada (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        setState(() => _testResult = 'Tiempo de espera agotado');
      } else if (e.error is SocketException) {
        setState(() => _testResult = 'No se pudo conectar al servidor');
      } else {
        setState(() => _testResult = 'Error de conexión');
      }
    } catch (e) {
      setState(() => _testResult = 'Error: ${e.toString()}');
    } finally {
      setState(() => _testing = false);
    }
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixText: suffix,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text('Configuración del Sistema',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          _buildSection(
            'Conexión al Servidor',
            Icons.dns,
            [
              _buildField(
                label: 'URL del servidor API',
                controller: _serverCtrl,
                hint: 'http://localhost:5000',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testing ? null : _testConnection,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering, size: 18),
                      label: Text(_testing ? 'Probando...' : 'Probar conexión'),
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(width: 12),
                    Text(_testResult!,
                        style: TextStyle(
                          color: _testResult!.contains('✓')
                              ? AppColors.success
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ],
              ),
            ],
          ),
          _buildSection(
            'Atención al Cliente',
            Icons.support_agent,
            [
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Tiempo estimado de espera',
                      controller: _timeCtrl,
                      keyboardType: TextInputType.number,
                      suffix: 'min',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField(
                      label: 'Máximo tickets por día',
                      controller: _ticketsCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildSection(
            'Información',
            Icons.info_outline,
            [
              Row(
                children: [
                  Text('Versión de la aplicación: ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const Text('1.0.0',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar configuración',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}