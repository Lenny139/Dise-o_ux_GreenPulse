import 'package:flutter/material.dart';
import '../app_palette.dart';
import '../core/app_text.dart';
import '../models/proyecto.dart';
import '../models/registro_agronomico.dart';
import '../models/alerta.dart';
import '../services/alertas_service.dart';
import '../services/cultivos_service.dart';
import '../services/estadisticas_service.dart';
import '../services/proyectos_service.dart';
import 'qr_scanner_view.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _proyectosService = ProyectosService();
  final _cultivosService = CultivosService();
  final _estadisticasService = EstadisticasService();
  final _alertasService = AlertasService();

  bool _loading = true;

  // Datos del banner
  Proyecto? _ultimoProyecto;
  String? _ultimoCultivoNombre;

  // Último registro (variables)
  RegistroAgronomico? _ultimoRegistro;

  // Última alerta
  Alerta? _ultimaAlerta;

  // Mes del calendario mostrado
  DateTime _mesCalendario = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final proyectos = await _proyectosService.getProyectos();
      if (!mounted) return;

      if (proyectos.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Último proyecto = el primero de la lista (ya viene ordenado por fecha desc)
      final proyecto = proyectos.first;
      final cultivos = await _cultivosService.getCultivos(proyecto.id);

      RegistroAgronomico? ultimoRegistro;
      String? cultivoNombre;

      if (cultivos.isNotEmpty) {
        final cultivo = cultivos.firstWhere(
          (c) => c.estado == 'activo',
          orElse: () => cultivos.first,
        );
        cultivoNombre = cultivo.displayName;

        // Obtener estadísticas para mostrar el último registro
        try {
          final stats = await _estadisticasService.getEstadisticas(cultivo.id);
          final promedios = _asMap(stats['promedios']);
          if (_toInt(stats['total_registros']) != null &&
              _toInt(stats['total_registros'])! > 0) {
            ultimoRegistro = RegistroAgronomico(
              registroId: 0,
              temperatura: _toDouble(promedios['temperatura_celsius']),
              humedad: _toDouble(promedios['humedad_relativa']),
              ph: _toDouble(promedios['ph_suelo']),
            );
          }
        } catch (_) {}
      }

      // Última alerta
      Alerta? ultimaAlerta;
      try {
        final alertas = await _alertasService.getAlertas();
        if (alertas.isNotEmpty) ultimaAlerta = alertas.first;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _ultimoProyecto = proyecto;
        _ultimoCultivoNombre = cultivoNombre;
        _ultimoRegistro = ultimoRegistro;
        _ultimaAlerta = ultimaAlerta;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return {};
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  // ─── Calendario ────────────────────────────────────────────────────────────

  void _mesAnterior() => setState(() => _mesCalendario = DateTime(
        _mesCalendario.year,
        _mesCalendario.month - 1,
      ));

  void _mesSiguiente() => setState(() => _mesCalendario = DateTime(
        _mesCalendario.year,
        _mesCalendario.month + 1,
      ));

  String _nombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── 1. BANNER ────────────────────────────────────────────────────
          _Banner(
            proyecto: _ultimoProyecto,
            cultivoNombre: _ultimoCultivoNombre,
          ),
          const SizedBox(height: 16),

          // ── 2. CALENDARIO (vacío) ────────────────────────────────────────
          _CalendarioCard(
            mes: _mesCalendario,
            nombreMes: _nombreMes(_mesCalendario.month),
            onAnterior: _mesAnterior,
            onSiguiente: _mesSiguiente,
          ),
          const SizedBox(height: 12),

          // ── 3. QR ────────────────────────────────────────────────────────
          _AccionCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'QR',
            subtitle: AppText.t(
              es: 'Escanea el QR de un cultivo para registrar datos',
              en: 'Scan a crop QR to log data',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // ── 4. VARIABLES ─────────────────────────────────────────────────
          _VariablesCard(registro: _ultimoRegistro),
          const SizedBox(height: 12),

          // ── 5. ÚLTIMA ALERTA ─────────────────────────────────────────────
          _UltimaAlertaCard(alerta: _ultimaAlerta),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({required this.proyecto, required this.cultivoNombre});
  final Proyecto? proyecto;
  final String? cultivoNombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                proyecto?.nombre ?? 'GreenPulse',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            proyecto == null
                ? AppText.t(
                    es: 'Crea tu primer proyecto para empezar.',
                    en: 'Create your first project to get started.',
                  )
                : cultivoNombre != null
                    ? '${proyecto!.tipo} · $cultivoNombre'
                    : AppText.t(
                        es: 'Sin cultivos aún en este proyecto.',
                        en: 'No crops yet in this project.',
                      ),
            style: const TextStyle(
              color: Color(0xFFD8F0E5),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarioCard extends StatelessWidget {
  const _CalendarioCard({
    required this.mes,
    required this.nombreMes,
    required this.onAnterior,
    required this.onSiguiente,
  });
  final DateTime mes;
  final String nombreMes;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    final diasEnMes = DateUtils.getDaysInMonth(mes.year, mes.month);
    final primerDia = DateTime(mes.year, mes.month, 1).weekday; // 1=lunes
    final hoy = DateTime.now();
    const diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header mes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onAnterior,
                  icon: const Icon(Icons.chevron_left_rounded),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  '$nombreMes ${mes.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimaryOf(context),
                  ),
                ),
                IconButton(
                  onPressed: onSiguiente,
                  icon: const Icon(Icons.chevron_right_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Días de la semana
            Row(
              children: diasSemana
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Grilla de días
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 2,
              ),
              itemCount: (primerDia - 1) + diasEnMes,
              itemBuilder: (ctx, index) {
                if (index < primerDia - 1) return const SizedBox();
                final dia = index - (primerDia - 1) + 1;
                final esHoy = mes.year == hoy.year &&
                    mes.month == hoy.month &&
                    dia == hoy.day;
                return Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: esHoy
                        ? BoxDecoration(
                            color: AppPalette.primary,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Center(
                      child: Text(
                        '$dia',
                        style: TextStyle(
                          fontSize: 12,
                          color: esHoy
                              ? Colors.white
                              : AppPalette.textPrimaryOf(ctx),
                          fontWeight:
                              esHoy ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              AppText.t(
                es: 'Sin eventos programados',
                en: 'No scheduled events',
              ),
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

class _AccionCard extends StatelessWidget {
  const _AccionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPalette.softSurfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppPalette.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppPalette.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.textSecondaryOf(context),
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

class _VariablesCard extends StatelessWidget {
  const _VariablesCard({required this.registro});
  final RegistroAgronomico? registro;

  String _fmt(double? v, String unidad) =>
      v != null ? '${v.toStringAsFixed(1)}$unidad' : '-';

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
                const Icon(
                  Icons.thermostat_rounded,
                  color: AppPalette.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  AppText.t(es: 'Variables', en: 'Variables'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimaryOf(context),
                  ),
                ),
                const Spacer(),
                Text(
                  AppText.t(es: 'Últimos promedios', en: 'Latest averages'),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (registro == null)
              Text(
                AppText.t(
                  es: 'Sin registros todavía.',
                  en: 'No records yet.',
                ),
                style: TextStyle(color: AppPalette.textSecondaryOf(context)),
              )
            else
              Row(
                children: [
                  _VarChip(
                    label: 'Temp.',
                    value: _fmt(registro!.temperatura, '°C'),
                    icon: Icons.thermostat_rounded,
                  ),
                  const SizedBox(width: 8),
                  _VarChip(
                    label: 'Humedad',
                    value: _fmt(registro!.humedad, '%'),
                    icon: Icons.water_drop_outlined,
                  ),
                  const SizedBox(width: 8),
                  _VarChip(
                    label: 'pH',
                    value: _fmt(registro!.ph, ''),
                    icon: Icons.science_outlined,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _VarChip extends StatelessWidget {
  const _VarChip({
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppPalette.softSurfaceOf(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppPalette.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppPalette.textPrimaryOf(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppPalette.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UltimaAlertaCard extends StatelessWidget {
  const _UltimaAlertaCard({required this.alerta});
  final Alerta? alerta;

  String _formatFecha(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

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
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  AppText.t(es: 'Última alerta', en: 'Latest alert'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            alerta == null
                ? Text(
                    AppText.t(
                      es: 'Sin alertas recientes ',
                      en: 'No recent alerts ',
                    ),
                    style: TextStyle(
                      color: AppPalette.textSecondaryOf(context),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color:
                              alerta!.leida == 0 ? Colors.orange : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alerta!.mensaje,
                              style: TextStyle(
                                color: AppPalette.textPrimaryOf(context),
                                fontSize: 13,
                              ),
                            ),
                            if (alerta!.fechaHora != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                _formatFecha(alerta!.fechaHora),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppPalette.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
