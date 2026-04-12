import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../core/app_text.dart';
import '../models/lote.dart';
import '../services/proyectos_service.dart';
import 'project_management_view.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _service = ProyectosService();
  bool _loading = true;
  List<Lote> _proyectos = const [];

  @override
  void initState() {
    super.initState();
    _loadProyectos();
  }

  Future<void> _loadProyectos() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getProyectos();
      if (!mounted) return;
      setState(() => _proyectos = data);
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

  Future<void> _crearProyectoDialog() async {
    final nombreCtrl = TextEditingController();
    final tipoCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final coordenadasCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppText.t(es: 'Crear proyecto', en: 'Create project')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(
                  labelText: AppText.t(es: 'Nombre', en: 'Name'),
                ),
              ),
              TextField(
                controller: tipoCtrl,
                decoration: InputDecoration(
                  labelText: AppText.t(
                    es: 'Tipo de cultivo',
                    en: 'Crop type',
                  ),
                ),
              ),
              TextField(
                controller: areaCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppText.t(es: 'Área m²', en: 'Area m²'),
                ),
              ),
              TextField(
                controller: coordenadasCtrl,
                decoration: InputDecoration(
                  labelText: AppText.t(
                    es: 'Coordenadas (latitud, longitud)',
                    en: 'Coordinates (latitude, longitude)',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppText.t(es: 'Cancelar', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppText.t(es: 'Crear', en: 'Create')),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final nombre = nombreCtrl.text.trim();
    final tipoCultivo = tipoCtrl.text.trim();
    final areaMetrosCuadrados = double.tryParse(areaCtrl.text.trim());
    final coordenadas = coordenadasCtrl.text.trim();

    if (nombre.isEmpty ||
        tipoCultivo.isEmpty ||
        areaMetrosCuadrados == null ||
        coordenadas.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa nombre, tipo de cultivo, área y coordenadas (latitud, longitud).',
          ),
        ),
      );
      return;
    }

    try {
      await _service.crearProyecto({
        'nombre': nombre,
        'tipo_cultivo': tipoCultivo,
        'area_metros_cuadrados': areaMetrosCuadrados,
        'coordenadas': coordenadas,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(AppText.t(es: 'Proyecto creado', en: 'Project created'))),
      );
      await _loadProyectos();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _eliminarProyecto(Lote lote) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppText.t(es: 'Eliminar proyecto', en: 'Delete project')),
        content: Text(
          AppText.t(
            es: '¿Eliminar "${lote.nombre}"?',
            en: 'Delete "${lote.nombre}"?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppText.t(es: 'Cancelar', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppText.t(es: 'Eliminar', en: 'Delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.eliminarProyecto(lote.loteId);
      if (!mounted) return;
      await _loadProyectos();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          AppText.t(es: 'Proyectos', en: 'Projects'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppText.t(
            es: 'Crea, organiza y administra tus proyectos de cultivo.',
            en: 'Create, organize and manage your crop projects.',
          ),
          style: TextStyle(color: AppPalette.textSecondaryOf(context)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _crearProyectoDialog,
                icon: const Icon(Icons.add_rounded),
                label: Text(AppText.t(es: 'Crear proyecto', en: 'Create project')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loadProyectos,
                icon: const Icon(Icons.tune_rounded),
                label: Text(AppText.t(es: 'Administrar proyecto', en: 'Manage project')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          AppText.t(es: 'Mis proyectos', en: 'My projects'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_proyectos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin proyectos aún'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _proyectos.length,
            itemBuilder: (context, index) {
              final lote = _proyectos[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey(lote.loteId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    await _eliminarProyecto(lote);
                    return false;
                  },
                  child: _ProjectTile(
                    title: lote.nombre,
                    status: lote.activo == 1 ? 'Activo' : 'Inactivo',
                    details:
                        '${lote.tipoCultivo ?? 'Sin tipo'} · ${lote.areaM2?.toStringAsFixed(1) ?? '-'} m²',
                    onManage: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProjectManagementScreen(loteId: lote.loteId),
                        ),
                      );
                      await _loadProyectos();
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.title,
    required this.status,
    required this.details,
    required this.onManage,
  });

  final String title;
  final String status;
  final String details;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppPalette.softSurfaceOf(context),
          child: const Icon(Icons.eco_rounded, color: AppPalette.primary),
        ),
        title: Text(title),
        subtitle: Text('$status · $details'),
        trailing: OutlinedButton(
          onPressed: onManage,
          child: Text(AppText.t(es: 'Gestionar', en: 'Manage')),
        ),
      ),
    );
  }
}
