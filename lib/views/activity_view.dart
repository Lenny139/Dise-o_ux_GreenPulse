import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../core/app_text.dart';
import '../models/cultivo.dart';
import '../models/proyecto.dart';
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

  bool _loadingProyectos = true;
  bool _loadingRegistros = false;

  List<Proyecto> _proyectos = const [];
  List<Cultivo> _cultivos = const [];
  List<RegistroAgronomico> _registros = const [];

  Proyecto? _proyectoSeleccionado;
  Cultivo? _cultivoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  Future<void> _cargarProyectos() async {
    setState(() => _loadingProyectos = true);
    try {
      final data = await _proyectosService.getProyectos();
      if (!mounted) return;
      setState(() => _proyectos = data);

      // Seleccionar automáticamente el primero si solo hay uno
      if (data.length == 1) {
        await _seleccionarProyecto(data.first);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loadingProyectos = false);
    }
  }

  Future<void> _seleccionarProyecto(Proyecto proyecto) async {
    setState(() {
      _proyectoSeleccionado = proyecto;
      _cultivoSeleccionado = null;
      _cultivos = const [];
      _registros = const [];
    });

    try {
      final cultivos = await _cultivosService.getCultivos(proyecto.id);
      if (!mounted) return;
      setState(() => _cultivos = cultivos);

      // Seleccionar automáticamente el primer cultivo activo
      if (cultivos.isNotEmpty) {
        final activo = cultivos.firstWhere(
          (c) => c.estado == 'activo',
          orElse: () => cultivos.first,
        );
        await _seleccionarCultivo(activo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _seleccionarCultivo(Cultivo cultivo) async {
    setState(() {
      _cultivoSeleccionado = cultivo;
      _registros = const [];
      _loadingRegistros = true;
    });

    try {
      final registros = await _cultivosService.getRegistros(cultivo.id);
      if (!mounted) return;
      setState(() => _registros = registros);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loadingRegistros = false);
    }
  }

  Future<void> _mostrarSelectorProyecto() async {
    if (_proyectos.isEmpty) return;

    final seleccionado = await showModalBottomSheet<Proyecto>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppText.t(es: 'Seleccionar proyecto', en: 'Select project'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _proyectos.length,
            itemBuilder: (ctx, i) {
              final p = _proyectos[i];
              final seleccionado = p.id == _proyectoSeleccionado?.id;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: seleccionado
                      ? AppPalette.primary.withValues(alpha: 0.15)
                      : AppPalette.softSurfaceOf(ctx),
                  child: Text(_iconoProyecto(p.tipo)),
                ),
                title: Text(p.nombre),
                subtitle: Text(p.tipo),
                trailing: seleccionado
                    ? const Icon(Icons.check_rounded, color: AppPalette.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, p),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (seleccionado != null && seleccionado.id != _proyectoSeleccionado?.id) {
      await _seleccionarProyecto(seleccionado);
    }
  }

  Future<void> _mostrarSelectorCultivo() async {
    if (_cultivos.isEmpty) return;

    final seleccionado = await showModalBottomSheet<Cultivo>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppText.t(es: 'Seleccionar cultivo', en: 'Select crop'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cultivos.length,
            itemBuilder: (ctx, i) {
              final c = _cultivos[i];
              final sel = c.id == _cultivoSeleccionado?.id;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: sel
                      ? AppPalette.primary.withValues(alpha: 0.15)
                      : AppPalette.softSurfaceOf(ctx),
                  child: Text(_iconoCultivo(c.plantaNombre)),
                ),
                title: Text(c.displayName),
                subtitle: Text(c.plantaNombre ?? ''),
                trailing: sel
                    ? const Icon(Icons.check_rounded, color: AppPalette.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (seleccionado != null && seleccionado.id != _cultivoSeleccionado?.id) {
      await _seleccionarCultivo(seleccionado);
    }
  }

  Future<void> _abrirNuevoRegistro() async {
    if (_cultivoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppText.t(
              es: 'Selecciona un proyecto y cultivo primero.',
              en: 'Select a project and crop first.',
            ),
          ),
        ),
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
      builder: (ctx) {
        bool sending = false;
        return StatefulBuilder(
          builder: (ctx, set) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  AppText.t(es: 'Nuevo registro', en: 'New record'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_proyectoSeleccionado?.nombre ?? ''} · ${_cultivoSeleccionado!.displayName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppPalette.textSecondaryOf(ctx),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: tempCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppText.t(
                      es: 'Temperatura °C',
                      en: 'Temperature °C',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: humedadCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppText.t(es: 'Humedad %', en: 'Humidity %'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'pH'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: obsCtrl,
                  decoration: InputDecoration(
                    labelText: AppText.t(
                      es: 'Observaciones (opcional)',
                      en: 'Notes (optional)',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: sending
                        ? null
                        : () async {
                            set(() => sending = true);
                            try {
                              await _cultivosService.crearRegistro(
                                _cultivoSeleccionado!.id,
                                {
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
                                  'metodo_ingreso': 'manual',
                                },
                              );
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (e) {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e
                                        .toString()
                                        .replaceFirst('Exception: ', ''),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              set(() => sending = false);
                            }
                          },
                    child: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            AppText.t(
                              es: 'Guardar registro',
                              en: 'Save record',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (created == true) {
      if (_cultivoSeleccionado != null) {
        await _seleccionarCultivo(_cultivoSeleccionado!);
      }
      final alertas = _cultivosService.lastAlertasGeneradas;
      if (alertas > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppText.t(
                es: '⚠️ Se generaron $alertas alertas',
                en: '⚠️ $alertas alerts generated',
              ),
            ),
          ),
        );
      }
    }
  }

  String _formatFecha(DateTime? d) {
    if (d == null) return '-';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}'
        ' · ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hoy = _registros.where((r) {
      final d = r.fechaHoraRegistro?.toLocal();
      if (d == null) return false;
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;

    final semana = _registros.where((r) {
      final d = r.fechaHoraRegistro;
      return d != null &&
          d.isAfter(
            DateTime.now().toUtc().subtract(const Duration(days: 7)),
          );
    }).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          AppText.t(es: 'Actividad', en: 'Activity'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 12),

        // ── Selector de proyecto y cultivo ──────────────────────────────────
        if (_loadingProyectos)
          const Center(child: CircularProgressIndicator())
        else if (_proyectos.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppText.t(
                  es: 'No tienes proyectos. Créalos en la pestaña Proyectos.',
                  en: 'No projects yet. Create them in the Projects tab.',
                ),
              ),
            ),
          )
        else ...[
          // Selector proyecto
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppPalette.softSurfaceOf(context),
                child: Text(
                  _proyectoSeleccionado != null
                      ? _iconoProyecto(_proyectoSeleccionado!.tipo)
                      : '🌾',
                ),
              ),
              title: Text(
                AppText.t(es: 'Proyecto', en: 'Project'),
                style: const TextStyle(
                    fontSize: 12, color: AppPalette.textSecondary),
              ),
              subtitle: Text(
                _proyectoSeleccionado?.nombre ??
                    AppText.t(
                      es: 'Selecciona un proyecto',
                      en: 'Select a project',
                    ),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textPrimaryOf(context),
                ),
              ),
              trailing: const Icon(Icons.expand_more_rounded),
              onTap: _mostrarSelectorProyecto,
            ),
          ),
          const SizedBox(height: 8),

          // Selector cultivo
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppPalette.softSurfaceOf(context),
                child: Text(
                  _cultivoSeleccionado != null
                      ? _iconoCultivo(_cultivoSeleccionado!.plantaNombre)
                      : '🌱',
                ),
              ),
              title: Text(
                AppText.t(es: 'Cultivo', en: 'Crop'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppPalette.textSecondary,
                ),
              ),
              subtitle: Text(
                _cultivoSeleccionado?.displayName ??
                    (_proyectoSeleccionado == null
                        ? AppText.t(
                            es: 'Primero elige un proyecto',
                            en: 'Choose a project first',
                          )
                        : _cultivos.isEmpty
                            ? AppText.t(
                                es: 'Sin cultivos en este proyecto',
                                en: 'No crops in this project',
                              )
                            : AppText.t(
                                es: 'Selecciona un cultivo',
                                en: 'Select a crop',
                              )),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textPrimaryOf(context),
                ),
              ),
              trailing: _cultivos.length > 1
                  ? const Icon(Icons.expand_more_rounded)
                  : null,
              onTap: _cultivos.length > 1 ? _mostrarSelectorCultivo : null,
            ),
          ),
          const SizedBox(height: 14),

          // Botón nuevo registro
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _cultivoSeleccionado != null ? _abrirNuevoRegistro : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                AppText.t(es: 'Nuevo registro', en: 'New record'),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _MiniStat(
                    label: AppText.t(es: 'Hoy', en: 'Today'),
                    value: hoy.toString(),
                    icon: Icons.today_rounded,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    label: AppText.t(es: 'Semana', en: 'Week'),
                    value: semana.toString(),
                    icon: Icons.date_range_rounded,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    label: AppText.t(es: 'Total', en: 'Total'),
                    value: _registros.length.toString(),
                    icon: Icons.bar_chart_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Historial
          Text(
            AppText.t(es: 'Historial reciente', en: 'Recent history'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppPalette.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 10),
          if (_loadingRegistros)
            const Center(child: CircularProgressIndicator())
          else if (_registros.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _cultivoSeleccionado == null
                      ? AppText.t(
                          es: 'Selecciona un cultivo para ver sus registros.',
                          en: 'Select a crop to see its records.',
                        )
                      : AppText.t(
                          es: 'Sin registros aún. Toca "Nuevo registro".',
                          en: 'No records yet. Tap "New record".',
                        ),
                ),
              ),
            )
          else
            ...(_registros.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppPalette.softSurfaceOf(context),
                      child: const Icon(
                        Icons.thermostat_rounded,
                        color: AppPalette.primary,
                      ),
                    ),
                    title: Text(
                      'T° ${r.temperatura?.toStringAsFixed(1) ?? '-'}°C  '
                      'H ${r.humedad?.toStringAsFixed(1) ?? '-'}%  '
                      'pH ${r.ph?.toStringAsFixed(1) ?? '-'}',
                    ),
                    subtitle: Text(
                      _cultivoSeleccionado?.displayName ?? '',
                      style: TextStyle(
                        color: AppPalette.textSecondaryOf(context),
                      ),
                    ),
                    trailing: Text(
                      _formatFecha(r.fechaHoraRegistro),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ),
              ),
            )),
        ],
      ],
    );
  }
}

String _iconoProyecto(String tipo) {
  switch (tipo.toLowerCase()) {
    case 'invernadero':
      return '🏠';
    case 'huerto':
      return '🌿';
    case 'parcela':
      return '🟫';
    case 'vivero':
      return '🌱';
    case 'jardín urbano':
      return '🏙️';
    case 'terraza':
      return '🏗️';
    default:
      return '🌾';
  }
}

String _iconoCultivo(String? nombre) {
  switch (nombre?.toLowerCase()) {
    case 'tomate':
      return '🍅';
    case 'maíz':
      return '🌽';
    case 'café arábica':
    case 'café robusta':
      return '☕';
    case 'arroz':
      return '🌾';
    case 'papa':
      return '🥔';
    case 'frijol':
      return '🫘';
    case 'aguacate':
      return '🥑';
    case 'banano':
    case 'plátano':
      return '🍌';
    case 'lechuga':
      return '🥬';
    case 'zanahoria':
      return '🥕';
    case 'mango':
      return '🥭';
    case 'naranja':
      return '🍊';
    case 'cacao':
      return '🍫';
    default:
      return '🌱';
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
          color: AppPalette.softSurfaceOf(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppPalette.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppPalette.textPrimaryOf(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppPalette.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
