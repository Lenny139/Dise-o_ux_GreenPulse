import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../core/app_text.dart';
import '../models/proyecto.dart';
import '../services/proyectos_service.dart';
import 'project_detail_view.dart';

/// Tipos de proyecto disponibles en la app
const _tiposProyecto = [
  'Finca',
  'Invernadero',
  'Huerto',
  'Parcela',
  'Vivero',
  'Jardín urbano',
  'Terraza',
];

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

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _service = ProyectosService();
  bool _loading = true;
  List<Proyecto> _proyectos = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getProyectos();
      if (!mounted) return;
      setState(() => _proyectos = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _crearDialog() async {
    final nombreCtrl = TextEditingController();
    final coordCtrl = TextEditingController();
    String tipo = _tiposProyecto.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(AppText.t(es: 'Nuevo proyecto', en: 'New project')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText: AppText.t(es: 'Nombre', en: 'Name'),
                    hintText: AppText.t(
                      es: 'Ej: Lote Norte',
                      en: 'E.g. North Lot',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppText.t(es: 'Tipo de proyecto', en: 'Project type'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: const InputDecoration(isDense: true),
                  items: _tiposProyecto
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Text(_iconoProyecto(t)),
                              const SizedBox(width: 8),
                              Text(t),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) set(() => tipo = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coordCtrl,
                  decoration: InputDecoration(
                    labelText: AppText.t(es: 'Coordenadas', en: 'Coordinates'),
                    hintText: '6.2530, -75.5736',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppText.t(es: 'Cancelar', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppText.t(es: 'Crear', en: 'Create')),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final nombre = nombreCtrl.text.trim();
    final coords = coordCtrl.text.trim();
    if (nombre.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppText.t(es: 'El nombre es obligatorio', en: 'Name is required'),
            ),
          ),
        );
      }
      return;
    }

    try {
      await _service.crearProyecto(
        nombre: nombre,
        tipo: tipo,
        coordenadas: coords.isEmpty ? null : coords,
      );
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _eliminar(Proyecto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppText.t(es: 'Eliminar', en: 'Delete')),
        content: Text(
          AppText.t(
            es: '¿Eliminar "${p.nombre}"?',
            en: 'Delete "${p.nombre}"?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppText.t(es: 'Cancelar', en: 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppText.t(es: 'Eliminar', en: 'Delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.eliminarProyecto(p.id);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Text(
              AppText.t(es: 'Proyectos', en: 'Projects'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppPalette.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppText.t(
                es: 'Cada proyecto es una ubicación con uno o más cultivos.',
                en: 'Each project is a location with one or more crops.',
              ),
              style: TextStyle(color: AppPalette.textSecondaryOf(context)),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_proyectos.isEmpty)
              _EmptyState(onCrear: _crearDialog)
            else
              ...(_proyectos.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProyectoCard(
                    proyecto: p,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(proyecto: p),
                        ),
                      );
                      _load();
                    },
                    onEliminar: () => _eliminar(p),
                  ),
                ),
              )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppText.t(es: 'Nuevo proyecto', en: 'New project')),
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ProyectoCard extends StatelessWidget {
  const _ProyectoCard({
    required this.proyecto,
    required this.onTap,
    required this.onEliminar,
  });

  final Proyecto proyecto;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppPalette.softSurfaceOf(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _iconoProyecto(proyecto.tipo),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proyecto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppPalette.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      children: [
                        _Chip(label: proyecto.tipo),
                        _Chip(
                          label:
                              '${proyecto.totalCultivos} '
                              '${proyecto.totalCultivos == 1 ? 'cultivo' : 'cultivos'}',
                          color: AppPalette.accent,
                        ),
                      ],
                    ),
                    if (proyecto.ubicacionTexto?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppPalette.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              proyecto.ubicacionTexto!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppPalette.textSecondaryOf(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'del') onEliminar();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'del',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          AppText.t(es: 'Eliminar', en: 'Delete'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg =
        color?.withValues(alpha: 0.15) ?? AppPalette.softSurfaceOf(context);
    final fg = color ?? AppPalette.textSecondaryOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCrear});
  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Text('🌾', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              AppText.t(es: 'Sin proyectos todavía', en: 'No projects yet'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppText.t(
                es: 'Crea tu primer proyecto para empezar.',
                en: 'Create your first project to get started.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.textSecondaryOf(context)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                AppText.t(es: 'Crear proyecto', en: 'Create project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
