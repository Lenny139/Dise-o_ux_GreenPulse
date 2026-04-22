import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../core/app_text.dart';
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
      ).showSnackBar(
        SnackBar(
          content: Text(
            AppText.t(
              es: 'Alerta marcada como leída',
              en: 'Alert marked as read',
            ),
          ),
        ),
      );
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
    if (value == null) return AppText.t(es: 'Sin fecha', en: 'No date');
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
      appBar: AppBar(
        title: Text(AppText.t(es: 'Notificaciones', en: 'Notifications')),
      ),
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
                          AppText.t(
                            es: 'No tienes alertas pendientes.',
                            en: 'You have no pending alerts.',
                          ),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                            child: Text(
                              AppText.t(es: 'Marcar leída', en: 'Mark as read'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
