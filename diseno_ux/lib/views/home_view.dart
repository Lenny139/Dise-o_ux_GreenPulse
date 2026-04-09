import 'package:flutter/material.dart';

import '../app_palette.dart';
import '../models/lote.dart';
import '../services/estadisticas_service.dart';
import '../services/eventos_service.dart';
import '../services/proyectos_service.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _proyectosService = ProyectosService();
  final _estadisticasService = EstadisticasService();
  final _eventosService = EventosService();

  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    final proyectos = await _proyectosService.getProyectos();
    if (proyectos.isEmpty) {
      return const _DashboardData();
    }

    final loteActivo = _pickProyectoActivo(proyectos);
    final estadisticas = await _estadisticasService.getEstadisticas(
      loteActivo.loteId,
    );
    final eventos = await _eventosService.getEventosPendientes();

    final kpisHoy = _asMap(estadisticas['kpis_hoy']);
    final temperatura = _toDouble(_asMap(kpisHoy['temperatura'])['promedio']);
    final humedad = _toDouble(_asMap(kpisHoy['humedad'])['promedio']);
    final ph = _toDouble(_asMap(kpisHoy['ph'])['promedio']);
    final totalRegistros = _toInt(kpisHoy['registros']) ?? 0;
    final proximoRiego = _asMap(eventos['proximo_riego']);

    return _DashboardData(
      temperaturaPromedio: temperatura,
      humedadPromedio: humedad,
      phPromedio: ph,
      totalRegistros: totalRegistros,
      proximoRiegoFecha: proximoRiego['fecha']?.toString(),
      proximoRiegoLote: proximoRiego['lote']?.toString(),
    );
  }

  Lote _pickProyectoActivo(List<Lote> lotes) {
    for (final lote in lotes) {
      if (lote.activo == 1) return lote;
    }
    return lotes.first;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data ?? const _DashboardData();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppPalette.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido a GreenPulse!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gestiona tus cultivos, registra actividades y consulta el estado de tus lotes en un solo lugar.',
                    style: TextStyle(color: Color(0xFFE4F5EC), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Opciones principales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: const [
                _OptionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Escanear QR',
                  subtitle: 'Identificar lote rápido',
                ),
                _OptionCard(
                  icon: Icons.thermostat_rounded,
                  title: 'Variables',
                  subtitle: 'Temperatura, humedad, pH',
                ),
                _OptionCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Calendario',
                  subtitle: 'Riego y fertilización',
                ),
                _OptionCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Alertas',
                  subtitle: 'Recordatorios importantes',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF6F0),
                  child: Icon(Icons.eco_rounded, color: AppPalette.primary),
                ),
                title: Text(
                  data.totalRegistros > 0
                      ? 'KPIs hoy: T° ${data.temperaturaPromedio?.toStringAsFixed(1) ?? '-'}°C · H ${data.humedadPromedio?.toStringAsFixed(1) ?? '-'}% · pH ${data.phPromedio?.toStringAsFixed(1) ?? '-'}'
                      : 'Sin registros aún',
                ),
                subtitle: Text(
                  data.proximoRiegoFecha != null
                      ? 'Próximo riego: ${data.proximoRiegoFecha} · ${data.proximoRiegoLote ?? ''}'
                      : 'Próximo riego: sin programación',
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardData {
  final double? temperaturaPromedio;
  final double? humedadPromedio;
  final double? phPromedio;
  final int totalRegistros;
  final String? proximoRiegoFecha;
  final String? proximoRiegoLote;

  const _DashboardData({
    this.temperaturaPromedio,
    this.humedadPromedio,
    this.phPromedio,
    this.totalRegistros = 0,
    this.proximoRiegoFecha,
    this.proximoRiegoLote,
  });
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppPalette.primary),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppPalette.textSecondary,
                    fontSize: 12,
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
