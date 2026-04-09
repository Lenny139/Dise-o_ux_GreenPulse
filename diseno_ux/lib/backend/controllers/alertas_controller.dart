import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';

Future<Response> listarAlertasNoLeidas(Request request) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  MySqlConnection? connection;

  try {
    connection = await openDatabaseConnection();

    final alertas = await connection.query(
      '''
      SELECT
        ag.alerta_id,
        ag.mensaje,
        ag.fecha_hora,
        ca.variable,
        l.nombre AS lote_nombre
      FROM ALERTA_GENERADA ag
      INNER JOIN CONFIGURACION_ALERTA ca ON ca.config_id = ag.config_id
      INNER JOIN REGISTRO_AGRONOMICO ra ON ra.registro_id = ag.registro_id
      INNER JOIN LOTE l ON l.lote_id = ra.lote_id
      WHERE ca.usuario_id = ? AND ag.leida = 0
      ORDER BY ag.fecha_hora DESC
      ''',
      [usuarioId],
    );

    final alertasList = alertas
        .map(
          (row) => {
            'alerta_id': _toInt(row['alerta_id']),
            'mensaje': row['mensaje'],
            'fecha_hora': _toIsoString(row['fecha_hora']),
            'variable': row['variable'],
            'lote_nombre': row['lote_nombre'],
          },
        )
        .toList();

    return Response.ok(
      jsonEncode({
        'total_no_leidas': alertasList.length,
        'alertas': alertasList,
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> marcarAlertaLeida(Request request, String alertaId) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final alertaIdInt = int.tryParse(alertaId.trim());

  if (alertaIdInt == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'alerta_id inválido'}),
      headers: {'content-type': 'application/json'},
    );
  }

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();

    final verifyOwnership = await connection.query(
      '''
      SELECT ag.alerta_id
      FROM ALERTA_GENERADA ag
      INNER JOIN CONFIGURACION_ALERTA ca ON ca.config_id = ag.config_id
      WHERE ag.alerta_id = ? AND ca.usuario_id = ?
      LIMIT 1
      ''',
      [alertaIdInt, usuarioId],
    );

    if (verifyOwnership.isEmpty) {
      return Response(
        404,
        body: jsonEncode({'error': 'Alerta no encontrada'}),
        headers: {'content-type': 'application/json'},
      );
    }

    await connection.query(
      'UPDATE ALERTA_GENERADA SET leida = 1 WHERE alerta_id = ?',
      [alertaIdInt],
    );

    return Response.ok(
      jsonEncode({'mensaje': 'Alerta marcada como leída'}),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
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

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is BigInt) return value.toInt();
  return int.tryParse(value.toString());
}

String? _toIsoString(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().toIso8601String();
  return DateTime.parse(value.toString()).toUtc().toIso8601String();
}
