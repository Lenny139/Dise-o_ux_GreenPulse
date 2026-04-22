import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../core/app_text.dart';
import '../services/plantas_service.dart';

// ─── Pantalla principal: lista de plantas ─────────────────────────────────────

class PlantasScreen extends StatefulWidget {
  const PlantasScreen({super.key});

  @override
  State<PlantasScreen> createState() => _PlantasScreenState();
}

class _PlantasScreenState extends State<PlantasScreen> {
  final _service = PlantasService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  List<PlantaSummary> _todas = const [];
  List<PlantaSummary> _filtradas = const [];
  List<String> _categorias = const [];
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final plantas = await _service.getPlantas();
      final cats = await _service.getCategorias();
      if (!mounted) return;
      setState(() {
        _todas = plantas;
        _filtradas = plantas;
        _categorias = cats;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtradas = _todas.where((p) {
        final coincideTexto = q.isEmpty ||
            p.nombreComun.toLowerCase().contains(q) ||
            (p.nombreCientifico?.toLowerCase().contains(q) ?? false);
        final coincideCategoria = _categoriaSeleccionada == null ||
            p.categoria == _categoriaSeleccionada;
        return coincideTexto && coincideCategoria;
      }).toList();
    });
  }

  void _seleccionarCategoria(String? cat) {
    setState(() => _categoriaSeleccionada = cat);
    _filtrar();
  }

  String _emojiCategoria(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'grano':      return '🌾';
      case 'fruta':      return '🍎';
      case 'hortaliza':  return '🥦';
      case 'tuberculo':  return '🥔';
      case 'industrial': return '🏭';
      case 'aromatica':  return '🌿';
      default:           return '🌱';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.t(es: 'Catálogo de plantas', en: 'Plant catalog')),
      ),
      body: Column(
        children: [
          // ── Buscador ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: AppText.t(
                  es: 'Buscar planta...',
                  en: 'Search plant...',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filtrar();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Filtro por categoría ──────────────────────────────────────────
          if (_categorias.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CatChip(
                    label: AppText.t(es: 'Todas', en: 'All'),
                    selected: _categoriaSeleccionada == null,
                    onTap: () => _seleccionarCategoria(null),
                  ),
                  ...(_categorias.map(
                    (cat) => _CatChip(
                      label: '${_emojiCategoria(cat)} $cat',
                      selected: _categoriaSeleccionada == cat,
                      onTap: () => _seleccionarCategoria(cat),
                    ),
                  )),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtradas.isEmpty
                    ? Center(
                        child: Text(
                          AppText.t(
                            es: 'Sin resultados',
                            en: 'No results',
                          ),
                          style: TextStyle(
                            color: AppPalette.textSecondaryOf(context),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtradas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final p = _filtradas[i];
                            return _PlantaTile(
                              planta: p,
                              emoji: _emojiCategoria(p.categoria),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PlantaDetalleScreen(plantaId: p.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Pantalla de detalle ──────────────────────────────────────────────────────

class PlantaDetalleScreen extends StatefulWidget {
  const PlantaDetalleScreen({super.key, required this.plantaId});
  final int plantaId;

  @override
  State<PlantaDetalleScreen> createState() => _PlantaDetalleScreenState();
}

class _PlantaDetalleScreenState extends State<PlantaDetalleScreen> {
  final _service = PlantasService();
  bool _loading = true;
  PlantaDetalle? _planta;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _service.getPlanta(widget.plantaId);
      if (!mounted) return;
      setState(() => _planta = p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_planta?.nombreComun ?? ''),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _planta == null
              ? Center(
                  child: Text(
                    AppText.t(es: 'No disponible', en: 'Not available'),
                  ),
                )
              : _DetalleBody(planta: _planta!),
    );
  }
}

class _DetalleBody extends StatelessWidget {
  const _DetalleBody({required this.planta});
  final PlantaDetalle planta;

  String _rango(double? min, double? max, String unidad) {
    if (min == null && max == null) return '-';
    if (min != null && max != null) return '$min – $max $unidad';
    if (min != null) return '≥ $min $unidad';
    return '≤ $max $unidad';
  }

  String _altitud(int? min, int? max) {
    if (min == null && max == null) return '-';
    if (min != null && max != null) return '$min – $max msnm';
    if (min != null) return '≥ $min msnm';
    return '≤ $max msnm';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _emojiCategoria(planta.categoria),
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planta.nombreComun,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.textPrimaryOf(context),
                            ),
                          ),
                          if (planta.nombreCientifico != null)
                            Text(
                              planta.nombreCientifico!,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppPalette.textSecondaryOf(context),
                              ),
                            ),
                          if (planta.categoria != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                planta.categoria!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppPalette.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (planta.esPerenne) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.recycling_rounded,
                        size: 14,
                        color: AppPalette.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppText.t(es: 'Planta perenne', en: 'Perennial plant'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppPalette.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Rangos óptimos
        _SeccionCard(
          titulo: AppText.t(es: 'Rangos óptimos', en: 'Optimal ranges'),
          icono: Icons.thermostat_rounded,
          children: [
            _DataRow(
              label: AppText.t(es: 'Temperatura', en: 'Temperature'),
              value: _rango(planta.temperaturaMin, planta.temperaturaMax, '°C'),
              icono: Icons.thermostat_outlined,
            ),
            _DataRow(
              label: AppText.t(es: 'Humedad', en: 'Humidity'),
              value: _rango(planta.humedadMin, planta.humedadMax, '%'),
              icono: Icons.water_drop_outlined,
            ),
            _DataRow(
              label: 'pH',
              value: _rango(planta.phMin, planta.phMax, ''),
              icono: Icons.science_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Ciclo y cultivo
        _SeccionCard(
          titulo: AppText.t(es: 'Ciclo y cultivo', en: 'Cycle & cultivation'),
          icono: Icons.calendar_month_rounded,
          children: [
            _DataRow(
              label: AppText.t(es: 'Ciclo', en: 'Cycle'),
              value: planta.cicloDiasMin != null || planta.cicloDiasMax != null
                  ? '${planta.cicloDiasMin ?? '?'} – ${planta.cicloDiasMax ?? '?'} días'
                  : '-',
              icono: Icons.timelapse_rounded,
            ),
            _DataRow(
              label: AppText.t(es: 'Agua', en: 'Water'),
              value: planta.requerimientoAgua ?? '-',
              icono: Icons.opacity_rounded,
            ),
            _DataRow(
              label: AppText.t(es: 'Altitud', en: 'Altitude'),
              value: _altitud(planta.altitudMinMsnm, planta.altitudMaxMsnm),
              icono: Icons.landscape_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Variedades
        if (planta.variedades != null && planta.variedades!.isNotEmpty) ...[
          _SeccionCard(
            titulo: AppText.t(es: 'Variedades', en: 'Varieties'),
            icono: Icons.list_rounded,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: planta.variedades!
                    .split(',')
                    .map((v) => v.trim())
                    .where((v) => v.isNotEmpty)
                    .map(
                      (v) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.softSurfaceOf(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          v,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppPalette.textPrimaryOf(context),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Región y notas
        if (planta.regionTipica != null || planta.notas != null)
          _SeccionCard(
            titulo: AppText.t(es: 'Información adicional', en: 'Additional info'),
            icono: Icons.info_outline_rounded,
            children: [
              if (planta.regionTipica != null)
                _DataRow(
                  label: AppText.t(es: 'Región típica', en: 'Typical region'),
                  value: planta.regionTipica!,
                  icono: Icons.location_on_outlined,
                ),
              if (planta.notas != null) ...[
                const SizedBox(height: 8),
                Text(
                  planta.notas!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppPalette.textSecondaryOf(context),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  String _emojiCategoria(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'grano':      return '🌾';
      case 'fruta':      return '🍎';
      case 'hortaliza':  return '🥦';
      case 'tuberculo':  return '🥔';
      case 'industrial': return '🏭';
      case 'aromatica':  return '🌿';
      default:           return '🌱';
    }
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _PlantaTile extends StatelessWidget {
  const _PlantaTile({
    required this.planta,
    required this.emoji,
    required this.onTap,
  });
  final PlantaSummary planta;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppPalette.softSurfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planta.nombreComun,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textPrimaryOf(context),
                      ),
                    ),
                    if (planta.nombreCientifico != null)
                      Text(
                        planta.nombreCientifico!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppPalette.textSecondaryOf(context),
                        ),
                      ),
                    if (planta.categoria != null)
                      Text(
                        planta.categoria!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppPalette.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppPalette.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppPalette.primary
              : AppPalette.softSurfaceOf(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppPalette.textPrimaryOf(context),
          ),
        ),
      ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  const _SeccionCard({
    required this.titulo,
    required this.icono,
    required this.children,
  });
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 16, color: AppPalette.primary),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.label,
    required this.value,
    required this.icono,
  });
  final String label;
  final String value;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 16, color: AppPalette.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppPalette.textSecondaryOf(context),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPalette.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
