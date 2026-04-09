import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/lote.dart';
import '../models/registro_agronomico.dart';
import '../services/cultivos_service.dart';
import '../services/proyectos_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _proyectosService = ProyectosService();
  final _cultivosService = CultivosService();

  bool _loading = true;
  Lote? _loteActivo;
  List<RegistroAgronomico> _registros = const [];

  @override
  void initState() {
    super.initState();
    _loadRegistros();
  }

  Future<void> _loadRegistros() async {
    setState(() => _loading = true);
    try {
      final proyectos = await _proyectosService.getProyectos();
      if (proyectos.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loteActivo = null;
          _registros = const [];
        });
        return;
      }

      final lote = _pickProyectoActivo(proyectos);
      final registros = await _cultivosService.getRegistros(lote.loteId);

      if (!mounted) return;
      setState(() {
        _loteActivo = lote;
        _registros = registros;
      });
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

  Lote _pickProyectoActivo(List<Lote> lotes) {
    for (final lote in lotes) {
      if (lote.activo == 1) return lote;
    }
    return lotes.first;
  }

  Future<void> _abrirNuevoRegistro() async {
    if (_loteActivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay proyecto activo disponible')),
      );
      return;
    }

    final tempCtrl = TextEditingController();
    final humedadCtrl = TextEditingController();
    final phCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        bool sending = false;
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nuevo registro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tempCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Temperatura °C',
                    ),
                  ),
                  TextField(
                    controller: humedadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Humedad %'),
                  ),
                  TextField(
                    controller: phCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'pH'),
                  ),
                  TextField(
                    controller: obsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: sending
                          ? null
                          : () async {
                              modalSetState(() => sending = true);
                              try {
                                await _cultivosService
                                    .crearRegistro(_loteActivo!.loteId, {
                                      'temperatura_celsius': double.tryParse(
                                        tempCtrl.text.trim(),
                                      ),
                                      'humedad_relativa': double.tryParse(
                                        humedadCtrl.text.trim(),
                                      ),
                                      'ph_suelo': double.tryParse(
                                        phCtrl.text.trim(),
                                      ),
                                      'observaciones': obsCtrl.text.trim(),
                                      'metodo_ingreso': 'MANUAL',
                                    });

                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                                modalSetState(() => sending = false);
                              }
                            },
                      child: sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar registro'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (created == true) {
      await _loadRegistros();
      final alertas = _cultivosService.lastAlertasGeneradas;
      if (alertas > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Se generaron $alertas alertas nuevas')),
        );
      }
    }
  }

  String _formatFecha(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm · $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final hoy = _registros.where((r) {
      final date = r.fechaHoraRegistro?.toLocal();
      if (date == null) return false;
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;

    final semana = _registros.where((r) {
      final date = r.fechaHoraRegistro;
      if (date == null) return false;
      return date.isAfter(
        DateTime.now().toUtc().subtract(const Duration(days: 7)),
      );
    }).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text(
          'Actividad',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Revisa el historial reciente de eventos en tus cultivos.',
          style: TextStyle(color: AppPalette.textSecondary),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _abrirNuevoRegistro,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo registro'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MiniStat(
                  label: 'Hoy',
                  value: hoy.toString(),
                  icon: Icons.today_rounded,
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  label: 'Semana',
                  value: semana.toString(),
                  icon: Icons.date_range_rounded,
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  label: 'Alertas',
                  value: _cultivosService.lastAlertasGeneradas.toString(),
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Historial reciente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_loteActivo == null || _registros.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin registros aún'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _registros.length,
            itemBuilder: (context, index) {
              final registro = _registros[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActivityTile(
                  icon: Icons.thermostat_rounded,
                  title: 'Registro de variables',
                  subtitle:
                      '${_loteActivo!.nombre} · T ${registro.temperatura?.toStringAsFixed(1) ?? '-'}° · H ${registro.humedad?.toStringAsFixed(1) ?? '-'}% · pH ${registro.ph?.toStringAsFixed(1) ?? '-'}',
                  time: _formatFecha(registro.fechaHoraRegistro),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppPalette.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppPalette.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF6F0),
          child: Icon(icon, color: AppPalette.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary),
        ),
        onTap: () {},
      ),
    );
  }
}
