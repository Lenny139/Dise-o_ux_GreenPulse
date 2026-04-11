import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../config/mysql_compat.dart';

Future<Response> obtenerAjustes(Request request) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  MySqlConnection? connection;

  try {
    connection = await openDatabaseConnection();
    await _asegurarTabla(connection);

    final rows = await connection.query(
      '''
      SELECT
        notificaciones_activas,
        sonidos_activos,
        idioma,
        tema,
        privacidad_modo,
        updated_at
      FROM AJUSTE_USUARIO
      WHERE usuario_id = ?
      LIMIT 1
      ''',
      [usuarioId],
    );

    if (rows.isEmpty) {
      return Response.ok(
        jsonEncode({'ajustes': _defaultAjustes()}),
        headers: {'content-type': 'application/json'},
      );
    }

    final row = rows.first;
    return Response.ok(
      jsonEncode({
        'ajustes': {
          'notificaciones_activas': _toInt(row['notificaciones_activas']) == 1,
          'sonidos_activos': _toInt(row['sonidos_activos']) == 1,
          'idioma': (row['idioma'] ?? 'Español').toString(),
          'tema': (row['tema'] ?? 'Claro (GreenPulse)').toString(),
          'privacidad_modo': (row['privacidad_modo'] ?? 'Estándar').toString(),
          'updated_at': _toIsoString(row['updated_at']),
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> actualizarAjustes(Request request) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final body = await request.readAsString();
  final data = jsonDecode(body) as Map<String, dynamic>;

  final notificacionesActivas = _toBool(data['notificaciones_activas']);
  final sonidosActivos = _toBool(data['sonidos_activos']);
  final idioma = data['idioma']?.toString().trim();
  final tema = data['tema']?.toString().trim();
  final privacidadModo = data['privacidad_modo']?.toString().trim();

  final hasAnyField =
      notificacionesActivas != null ||
      sonidosActivos != null ||
      (idioma != null && idioma.isNotEmpty) ||
      (tema != null && tema.isNotEmpty) ||
      (privacidadModo != null && privacidadModo.isNotEmpty);

  if (!hasAnyField) {
    return Response(
      400,
      body: jsonEncode({'error': 'No se enviaron campos para actualizar'}),
      headers: {'content-type': 'application/json'},
    );
  }

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();
    await _asegurarTabla(connection);

    final existing = await connection.query(
      'SELECT usuario_id FROM AJUSTE_USUARIO WHERE usuario_id = ? LIMIT 1',
      [usuarioId],
    );

    if (existing.isEmpty) {
      await connection.query(
        '''
        INSERT INTO AJUSTE_USUARIO (
          usuario_id,
          notificaciones_activas,
          sonidos_activos,
          idioma,
          tema,
          privacidad_modo,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, UTC_TIMESTAMP(), UTC_TIMESTAMP())
        ''',
        [
          usuarioId,
          (notificacionesActivas ?? true) ? 1 : 0,
          (sonidosActivos ?? false) ? 1 : 0,
          (idioma == null || idioma.isEmpty) ? 'Español' : idioma,
          (tema == null || tema.isEmpty) ? 'Claro (GreenPulse)' : tema,
          (privacidadModo == null || privacidadModo.isEmpty)
              ? 'Estándar'
              : privacidadModo,
        ],
      );
    } else {
      final fields = <String>[];
      final values = <dynamic>[];

      if (notificacionesActivas != null) {
        fields.add('notificaciones_activas = ?');
        values.add(notificacionesActivas ? 1 : 0);
      }
      if (sonidosActivos != null) {
        fields.add('sonidos_activos = ?');
        values.add(sonidosActivos ? 1 : 0);
      }
      if (idioma != null && idioma.isNotEmpty) {
        fields.add('idioma = ?');
        values.add(idioma);
      }
      if (tema != null && tema.isNotEmpty) {
        fields.add('tema = ?');
        values.add(tema);
      }
      if (privacidadModo != null && privacidadModo.isNotEmpty) {
        fields.add('privacidad_modo = ?');
        values.add(privacidadModo);
      }

      fields.add('updated_at = UTC_TIMESTAMP()');
      values.add(usuarioId);

      await connection.query(
        'UPDATE AJUSTE_USUARIO SET ${fields.join(', ')} WHERE usuario_id = ?',
        values,
      );
    }

    final rows = await connection.query(
      '''
      SELECT
        notificaciones_activas,
        sonidos_activos,
        idioma,
        tema,
        privacidad_modo,
        updated_at
      FROM AJUSTE_USUARIO
      WHERE usuario_id = ?
      LIMIT 1
      ''',
      [usuarioId],
    );

    final row = rows.first;
    return Response.ok(
      jsonEncode({
        'mensaje': 'Ajustes actualizados',
        'ajustes': {
          'notificaciones_activas': _toInt(row['notificaciones_activas']) == 1,
          'sonidos_activos': _toInt(row['sonidos_activos']) == 1,
          'idioma': (row['idioma'] ?? 'Español').toString(),
          'tema': (row['tema'] ?? 'Claro (GreenPulse)').toString(),
          'privacidad_modo': (row['privacidad_modo'] ?? 'Estándar').toString(),
          'updated_at': _toIsoString(row['updated_at']),
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<void> _asegurarTabla(MySqlConnection connection) async {
  await connection.query(
    '''
    CREATE TABLE IF NOT EXISTS AJUSTE_USUARIO (
      usuario_id INT PRIMARY KEY,
      notificaciones_activas TINYINT(1) NOT NULL DEFAULT 1,
      sonidos_activos TINYINT(1) NOT NULL DEFAULT 0,
      idioma VARCHAR(30) NOT NULL DEFAULT 'Español',
      tema VARCHAR(60) NOT NULL DEFAULT 'Claro (GreenPulse)',
      privacidad_modo VARCHAR(30) NOT NULL DEFAULT 'Estándar',
      created_at DATETIME NOT NULL,
      updated_at DATETIME NOT NULL
    )
    ''',
  );
}

Map<String, dynamic> _defaultAjustes() {
  return {
    'notificaciones_activas': true,
    'sonidos_activos': false,
    'idioma': 'Español',
    'tema': 'Claro (GreenPulse)',
    'privacidad_modo': 'Estándar',
    'updated_at': null,
  };
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

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase().trim();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value ? 1 : 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is BigInt) return value.toInt();
  return int.tryParse(value.toString());
}

String? _toIsoString(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().toIso8601String();
  return DateTime.parse(value.toString()).toUtc().toIso8601String();
}
