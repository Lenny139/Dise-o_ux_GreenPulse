import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/lote.dart';
import '../services/proyectos_service.dart';

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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear proyecto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: tipoCtrl,
                decoration: const InputDecoration(labelText: 'Tipo de cultivo'),
              ),
              TextField(
                controller: areaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Área m²'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      await _service.crearProyecto({
        'nombre': nombreCtrl.text.trim(),
        'tipo_cultivo': tipoCtrl.text.trim(),
        'area_m2': double.tryParse(areaCtrl.text.trim()),
        'coordenadas': '',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proyecto creado')));
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
        title: const Text('Eliminar proyecto'),
        content: Text('¿Eliminar "${lote.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
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
        const Text(
          'Proyectos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Crea, organiza y administra tus proyectos de cultivo.',
          style: TextStyle(color: AppPalette.textSecondary),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _crearProyectoDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear proyecto'),
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
                label: const Text('Administrar proyecto'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Mis proyectos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimary,
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
  });

  final String title;
  final String status;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF6F0),
          child: Icon(Icons.eco_rounded, color: AppPalette.primary),
        ),
        title: Text(title),
        subtitle: Text('$status · $details'),
        trailing: OutlinedButton(
          onPressed: () {},
          child: const Text('Gestionar'),
        ),
      ),
    );
  }
}
