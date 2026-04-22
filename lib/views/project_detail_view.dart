import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../core/app_text.dart';
import '../models/cultivo.dart';
import '../models/proyecto.dart';
import '../services/cultivos_service.dart';
import '../services/plantas_service.dart';

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

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.proyecto});
  final Proyecto proyecto;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _cultivosService = CultivosService();
  final _plantasService = PlantasService();

  bool _loading = true;
  List<Cultivo> _cultivos = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _cultivosService.getCultivos(widget.proyecto.id);
      if (!mounted) return;
      setState(() => _cultivos = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _agregarCultivo() async {
    // Mostrar loading mientras carga plantas
    List<PlantaSummary> plantas = [];
    try {
      plantas = await _plantasService.getPlantas();
    } catch (_) {}

    if (!mounted) return;

    if (plantas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el catálogo de plantas'),
        ),
      );
      return;
    }

    // Capturamos la selección en una variable local al método
    // para evitar problemas con closures del StatefulBuilder
    int plantaSeleccionadaIndex = 0;
    final loteCtrl = TextEditingController();
    final areaCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(AppText.t(es: 'Agregar cultivo', en: 'Add crop')),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppText.t(es: 'Tipo de plantación', en: 'Crop type'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Usamos índice en lugar de objeto para evitar problemas de layout
                  DropdownButtonFormField<int>(
                    value: plantaSeleccionadaIndex,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true),
                    items: List.generate(
                      plantas.length,
                      (i) => DropdownMenuItem<int>(
                        value: i,
                        child: Text(
                          '${_iconoCultivo(plantas[i].nombreComun)} ${plantas[i].nombreComun}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) set(() => plantaSeleccionadaIndex = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: loteCtrl,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        es: 'Nombre del lote',
                        en: 'Lot name',
                      ),
                      hintText: AppText.t(
                        es: 'Ej: Sector A',
                        en: 'E.g. Sector A',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: areaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        es: 'Área m² (opcional)',
                        en: 'Area m² (optional)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppText.t(es: 'Cancelar', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppText.t(es: 'Agregar', en: 'Add')),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final plantaElegida = plantas[plantaSeleccionadaIndex];
    final nombreLote = loteCtrl.text.trim().isEmpty
        ? plantaElegida.nombreComun
        : loteCtrl.text.trim();
    final areaM2 = double.tryParse(areaCtrl.text.trim());

    try {
      await _cultivosService.crearCultivo(
        widget.proyecto.id,
        plantaId: plantaElegida.id,
        nombreLote: nombreLote,
        areaM2: areaM2,
      );
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _eliminarCultivo(Cultivo c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppText.t(es: 'Eliminar cultivo', en: 'Delete crop')),
        content: Text(
          AppText.t(
            es: '¿Eliminar "${c.displayName}"?',
            en: 'Delete "${c.displayName}"?',
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
      await _cultivosService.eliminarCultivo(c.id);
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
    final p = widget.proyecto;
    return Scaffold(
      appBar: AppBar(title: Text(p.nombre)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Info del proyecto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Text(
                      _iconoProyecto(p.tipo),
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.softSurfaceOf(context),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p.tipo,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppPalette.primary,
                              ),
                            ),
                          ),
                          if (p.ubicacionTexto?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Text(
                              p.ubicacionTexto!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppPalette.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Header cultivos — solo texto, sin botón extra
            Text(
              AppText.t(es: 'Cultivos', en: 'Crops'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_cultivos.isEmpty)
              _EmptyCultivos()
            else
              ...(_cultivos.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CultivoTile(
                    cultivo: c,
                    onEliminar: () => _eliminarCultivo(c),
                  ),
                ),
              )),
          ],
        ),
      ),
      // Un solo FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarCultivo,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppText.t(es: 'Nuevo cultivo', en: 'New crop')),
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _CultivoTile extends StatelessWidget {
  const _CultivoTile({required this.cultivo, required this.onEliminar});
  final Cultivo cultivo;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final activo = cultivo.estado == 'activo';
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: activo
                ? AppPalette.softSurfaceOf(context)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _iconoCultivo(cultivo.plantaNombre),
              style: TextStyle(
                fontSize: 22,
                color: activo ? null : Colors.grey,
              ),
            ),
          ),
        ),
        title: Text(
          cultivo.nombreLote?.isNotEmpty == true
              ? cultivo.nombreLote!
              : cultivo.plantaNombre ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: activo ? AppPalette.textPrimaryOf(context) : Colors.grey,
          ),
        ),
        subtitle: Text(
          [
            if (cultivo.plantaNombre != null) cultivo.plantaNombre!,
            if (cultivo.areaM2 != null)
              '${cultivo.areaM2!.toStringAsFixed(0)} m²',
            if (!activo) 'Inactivo',
          ].join(' · '),
          style: TextStyle(color: AppPalette.textSecondaryOf(context)),
        ),
        trailing: activo
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onEliminar,
              )
            : null,
      ),
    );
  }
}

class _EmptyCultivos extends StatelessWidget {
  const _EmptyCultivos();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              AppText.t(es: 'Sin cultivos aún', en: 'No crops yet'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppText.t(
                es: 'Usa el botón verde para agregar tu primer cultivo.',
                en: 'Use the green button to add your first crop.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppPalette.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
