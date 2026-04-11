import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/alerta.dart';
import '../services/alertas_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = AlertasService();
  bool _loading = true;
  List<Alerta> _alertas = const [];

  @override
  void initState() {
    super.initState();
    _loadAlertas();
  }

  Future<void> _loadAlertas() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAlertas();
      if (!mounted) return;
      setState(() => _alertas = data);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _marcarLeida(Alerta alerta) async {
    try {
      await _service.marcarLeida(alerta.alertaId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alerta marcada como leída')));
      await _loadAlertas();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Sin fecha';
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: RefreshIndicator(
        onRefresh: _loadAlertas,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _alertas.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No tienes alertas pendientes.',
                      style: TextStyle(
                        color: AppPalette.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _alertas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final alerta = _alertas[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.notification_important_rounded,
                        color: AppPalette.primary,
                      ),
                      title: Text(alerta.mensaje),
                      subtitle: Text(_formatDate(alerta.fechaHora)),
                      trailing: TextButton(
                        onPressed: () => _marcarLeida(alerta),
                        child: const Text('Marcar leída'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
