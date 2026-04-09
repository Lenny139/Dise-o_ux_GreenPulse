import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';

Future<Response> listarEventosPendientes(Request request) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  MySqlConnection? connection;

  try {
    connection = await openDatabaseConnection();

    final proximoRiego = await connection.query(
      '''
      SELECT
        eo.evento_id,
        eo.fecha_programada,
        l.nombre AS lote_nombre
      FROM EVENTO_OPERATIVO eo
      INNER JOIN LOTE l ON l.lote_id = eo.lote_id
      INNER JOIN TIPO_LABOR tl ON tl.tipo_labor_id = eo.tipo_labor_id
      WHERE eo.usuario_id = ? AND eo.estado = 'PENDIENTE' AND LOWER(tl.nombre) LIKE '%riego%'
      ORDER BY eo.fecha_programada ASC
      LIMIT 1
      ''',
      [usuarioId],
    );

    Map<String, dynamic>? proximoRiegoMap;
    if (proximoRiego.isNotEmpty) {
      final row = proximoRiego.first;
      proximoRiegoMap = {
        'fecha': _toIsoString(row['fecha_programada']),
        'lote': row['lote_nombre'],
      };
    }

    final eventosPendientes = await connection.query(
      '''
      SELECT
        eo.evento_id,
        eo.fecha_programada,
        eo.observaciones,
        eo.estado,
        l.nombre AS lote_nombre,
        tl.nombre AS tipo_labor
      FROM EVENTO_OPERATIVO eo
      INNER JOIN LOTE l ON l.lote_id = eo.lote_id
      INNER JOIN TIPO_LABOR tl ON tl.tipo_labor_id = eo.tipo_labor_id
      WHERE eo.usuario_id = ? AND eo.estado = 'PENDIENTE'
      ORDER BY eo.fecha_programada ASC
      ''',
      [usuarioId],
    );

    final eventosList = eventosPendientes
        .map(
          (row) => {
            'evento_id': _toInt(row['evento_id']),
            'fecha_programada': _toIsoString(row['fecha_programada']),
            'observaciones': row['observaciones'],
            'estado': row['estado'],
            'lote_nombre': row['lote_nombre'],
            'tipo_labor': row['tipo_labor'],
          },
        )
        .toList();

    return Response.ok(
      jsonEncode({
        'proximo_riego': proximoRiegoMap,
        'eventos_pendientes': eventosList,
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> crearEvento(Request request) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final body = await request.readAsString();
  final Map<String, dynamic> data = jsonDecode(body) as Map<String, dynamic>;

  final loteId = _toInt(data['lote_id']);
  final tipoLaborId = _toInt(data['tipo_labor_id']);
  final fechaProgramada = (data['fecha_programada'] ?? '').toString().trim();
  final observaciones = (data['observaciones'] ?? '').toString().trim();

  if (loteId == null || tipoLaborId == null || fechaProgramada.isEmpty) {
    return Response(
      400,
      body: jsonEncode({
        'error': 'lote_id, tipo_labor_id y fecha_programada son obligatorios',
      }),
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
        body: jsonEncode({'error': 'Lote no encontrado'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final result = await connection.query(
      '''
      INSERT INTO EVENTO_OPERATIVO (
        lote_id,
        usuario_id,
        tipo_labor_id,
        fecha_programada,
        observaciones,
        estado,
        fecha_completado,
        sync_estado
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        loteId,
        usuarioId,
        tipoLaborId,
        fechaProgramada,
        observaciones,
        'PENDIENTE',
        null,
        'PENDING',
      ],
    );

    final eventoId = result.insertId;
    if (eventoId == null) {
      throw StateError('No se pudo crear el evento');
    }

    return Response(
      201,
      body: jsonEncode({'evento_id': eventoId, 'mensaje': 'Evento programado'}),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> completarEvento(Request request, String eventoId) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final eventoIdInt = int.tryParse(eventoId.trim());

  if (eventoIdInt == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'evento_id inválido'}),
      headers: {'content-type': 'application/json'},
    );
  }

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();

    final ownership = await connection.query(
      '''
      SELECT eo.evento_id
      FROM EVENTO_OPERATIVO eo
      WHERE eo.evento_id = ? AND eo.usuario_id = ?
      LIMIT 1
      ''',
      [eventoIdInt, usuarioId],
    );

    if (ownership.isEmpty) {
      return Response(
        404,
        body: jsonEncode({'error': 'Evento no encontrado'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final now = DateTime.now().toUtc();
    await connection.query(
      'UPDATE EVENTO_OPERATIVO SET estado = ?, fecha_completado = ? WHERE evento_id = ?',
      ['COMPLETADO', now, eventoIdInt],
    );

    return Response.ok(
      jsonEncode({'mensaje': 'Evento marcado como completado'}),
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
