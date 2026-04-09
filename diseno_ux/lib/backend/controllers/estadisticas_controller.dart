import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';

Future<Response> obtenerEstadisticas(Request request, String cultivoId) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final loteId = int.tryParse(cultivoId.trim());

  if (loteId == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'cultivo_id inválido'}),
      headers: {'content-type': 'application/json'},
    );
  }

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();

    final ownership = await connection.query(
      '''
      SELECT l.lote_id
      FROM LOTE l
      INNER JOIN FINCA f ON f.finca_id = l.finca_id
      WHERE l.lote_id = ? AND f.usuario_id = ?
      LIMIT 1
      ''',
      [loteId, usuarioId],
    );

    if (ownership.isEmpty) {
      return Response(
        404,
        body: jsonEncode({'error': 'Cultivo no encontrado'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final kpisHoy = await _calcularKPIs(connection, loteId, 1);
    final kpisSemana = await _calcularKPIs(connection, loteId, 7);
    final tendenciaTemperatura = await _obtenerTendencia(
      connection,
      loteId,
      'temperatura',
      5,
    );
    final tendenciaPh = await _obtenerTendencia(connection, loteId, 'ph', 5);
    final alertasActivas = await _obtenerAlertasActivas(
      connection,
      loteId,
      usuarioId,
    );

    return Response.ok(
      jsonEncode({
        'lote_id': 'lote_$loteId',
        'kpis_hoy': kpisHoy,
        'kpis_semana': kpisSemana,
        'tendencia_temperatura': tendenciaTemperatura,
        'tendencia_ph': tendenciaPh,
        'alertas_activas': alertasActivas,
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> obtenerReporteMensual(
  Request request,
  String proyectoId,
) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final loteId = _extraerLoteId(proyectoId);
  if (loteId == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'proyecto_id inválido'}),
      headers: {'content-type': 'application/json'},
    );
  }

  final mes = request.url.queryParameters['mes'];
  if (mes == null || !RegExp(r'^\d{4}-\d{2}$').hasMatch(mes)) {
    return Response(
      400,
      body: jsonEncode({'error': 'mes debe tener formato YYYY-MM'}),
      headers: {'content-type': 'application/json'},
    );
  }

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();

    final ownership = await connection.query(
      '''
      SELECT l.lote_id
      FROM LOTE l
      INNER JOIN FINCA f ON f.finca_id = l.finca_id
      WHERE l.lote_id = ? AND f.usuario_id = ?
      LIMIT 1
      ''',
      [loteId, usuarioId],
    );

    if (ownership.isEmpty) {
      return Response(
        404,
        body: jsonEncode({'error': 'Proyecto no encontrado'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final mesInicio = '$mes-01';
    final partes = mes.split('-');
    final ano = int.parse(partes[0]);
    final mesNum = int.parse(partes[1]);

    final mesProximo = mesNum == 12
        ? DateTime(ano + 1, 1, 1)
        : DateTime(ano, mesNum + 1, 1);
    final mesFin = DateTime(
      mesProximo.year,
      mesProximo.month,
      mesProximo.day,
    ).subtract(const Duration(days: 1)).toIso8601String();

    final registros = await connection.query(
      '''
      SELECT COUNT(*) AS total, 
             AVG(temperatura) AS temp_prom, AVG(humedad) AS humedad_prom, AVG(ph) AS ph_prom
      FROM REGISTRO_AGRONOMICO
      WHERE lote_id = ? 
        AND fecha_hora_registro >= ? 
        AND fecha_hora_registro <= ?
      ''',
      [loteId, mesInicio, mesFin],
    );

    final row = registros.first;
    final totalRegistros = _toInt(row['total']) ?? 0;
    final tempProm = _toDouble(row['temp_prom']);
    final humedadProm = _toDouble(row['humedad_prom']);
    final phProm = _toDouble(row['ph_prom']);

    final eventos = await connection.query(
      '''
      SELECT COUNT(*) AS total
      FROM EVENTO_OPERATIVO
      WHERE lote_id = ? 
        AND estado = 'COMPLETADO'
        AND fecha_completado >= ? 
        AND fecha_completado <= ?
      ''',
      [loteId, mesInicio, mesFin],
    );

    final eventosCompletados = _toInt(eventos.first['total']) ?? 0;

    final alertas = await connection.query(
      '''
      SELECT COUNT(*) AS total
      FROM ALERTA_GENERADA ag
      INNER JOIN REGISTRO_AGRONOMICO ra ON ra.registro_id = ag.registro_id
      WHERE ra.lote_id = ? 
        AND ag.fecha_hora >= ? 
        AND ag.fecha_hora <= ?
      ''',
      [loteId, mesInicio, mesFin],
    );

    final alertasGeneradas = _toInt(alertas.first['total']) ?? 0;

    return Response.ok(
      jsonEncode({
        'mes': mes,
        'total_registros': totalRegistros,
        'promedios': {
          'temperatura': tempProm,
          'humedad': humedadProm,
          'ph': phProm,
        },
        'eventos_completados': eventosCompletados,
        'alertas_generadas': alertasGeneradas,
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Map<String, dynamic>> _calcularKPIs(
  MySqlConnection connection,
  int loteId,
  int dias,
) async {
  final rows = await connection.query(
    '''
    SELECT
      COUNT(*) AS registros,
      AVG(temperatura) AS temp_prom,
      MIN(temperatura) AS temp_min,
      MAX(temperatura) AS temp_max,
      AVG(humedad) AS humedad_prom,
      MIN(humedad) AS humedad_min,
      MAX(humedad) AS humedad_max,
      AVG(ph) AS ph_prom,
      MIN(ph) AS ph_min,
      MAX(ph) AS ph_max
    FROM REGISTRO_AGRONOMICO
    WHERE lote_id = ? AND fecha_hora_registro >= (NOW() - INTERVAL ? DAY)
    ''',
    [loteId, dias],
  );

  final row = rows.first;
  return {
    'registros': _toInt(row['registros']) ?? 0,
    'temperatura': {
      'promedio': _toDouble(row['temp_prom']),
      'min': _toDouble(row['temp_min']),
      'max': _toDouble(row['temp_max']),
    },
    'humedad': {
      'promedio': _toDouble(row['humedad_prom']),
      'min': _toDouble(row['humedad_min']),
      'max': _toDouble(row['humedad_max']),
    },
    'ph': {
      'promedio': _toDouble(row['ph_prom']),
      'min': _toDouble(row['ph_min']),
      'max': _toDouble(row['ph_max']),
    },
  };
}

Future<List<dynamic>> _obtenerTendencia(
  MySqlConnection connection,
  int loteId,
  String campo,
  int cantidad,
) async {
  final rows = await connection.query(
    '''
    SELECT $campo FROM REGISTRO_AGRONOMICO
    WHERE lote_id = ? AND $campo IS NOT NULL
    ORDER BY fecha_hora_registro DESC
    LIMIT ?
    ''',
    [loteId, cantidad],
  );

  final valores = rows
      .map((row) => _toDouble(row[campo]))
      .whereType<double>()
      .toList();
  return valores.reversed.toList();
}

Future<List<Map<String, dynamic>>> _obtenerAlertasActivas(
  MySqlConnection connection,
  int loteId,
  int usuarioId,
) async {
  final rows = await connection.query(
    '''
    SELECT
      ag.alerta_id,
      ag.mensaje,
      ag.fecha_hora,
      ca.variable
    FROM ALERTA_GENERADA ag
    INNER JOIN CONFIGURACION_ALERTA ca ON ca.config_id = ag.config_id
    INNER JOIN REGISTRO_AGRONOMICO ra ON ra.registro_id = ag.registro_id
    WHERE ra.lote_id = ? AND ca.usuario_id = ? AND ag.leida = 0
    ORDER BY ag.fecha_hora DESC
    ''',
    [loteId, usuarioId],
  );

  return rows.map((row) {
    final variable = row['variable'].toString();
    String tipo = 'alerta';
    String nivel = 'advertencia';

    if (variable.contains('TEMPERATURA')) {
      tipo = 'temperatura_alta';
    } else if (variable.contains('HUMEDAD')) {
      tipo = 'humedad_baja';
    } else if (variable.contains('PH')) {
      tipo = 'ph_alto';
    }

    return {
      'tipo': tipo,
      'mensaje': row['mensaje'],
      'nivel': nivel,
      'fecha': _toIsoString(row['fecha_hora']),
    };
  }).toList();
}

int _usuarioIdDesdeRequest(Request request) {
  final usuario = request.context['usuario'];
  if (usuario is Map) {
    final usuarioId = usuario['usuario_id'];
    final parsed = _toInt(usuarioId);
    if (parsed != null) {
      return parsed;
    }
  }
  throw StateError('Usuario autenticado no encontrado en el contexto');
}

int? _extraerLoteId(String proyectoId) {
  final match = RegExp(
    r'^lote_(\d+)$',
    caseSensitive: false,
  ).firstMatch(proyectoId.trim());
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }
  return int.tryParse(proyectoId.trim());
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is BigInt) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _toIsoString(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().toIso8601String();
  return DateTime.parse(value.toString()).toUtc().toIso8601String();
}
