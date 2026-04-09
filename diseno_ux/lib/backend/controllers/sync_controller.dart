import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';

const _jsonHeaders = {'content-type': 'application/json'};

Future<Response> pushSync(Request request) async {
  final usuarioId = _usuarioIdDesdeRequest(request);

  Map<String, dynamic> body;
  try {
    body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  } catch (_) {
    return Response(
      400,
      body: jsonEncode({'error': 'JSON inválido'}),
      headers: _jsonHeaders,
    );
  }

  final registrosRaw = body['registros'];
  if (registrosRaw is! List) {
    return Response(
      400,
      body: jsonEncode({'error': 'registros debe ser un arreglo'}),
      headers: _jsonHeaders,
    );
  }

  var sincronizados = 0;
  var errores = 0;
  final resultados = <Map<String, dynamic>>[];

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();

    for (final entry in registrosRaw) {
      if (entry is! Map) {
        errores++;
        resultados.add({
          'id_local': null,
          'id_remoto': null,
          'tabla': null,
          'estado': 'ERROR',
          'detalle': 'Registro inválido',
        });
        continue;
      }

      final registro = Map<String, dynamic>.from(entry);
      final tabla = (registro['tabla'] ?? '').toString().trim().toUpperCase();
      final operacion = (registro['operacion'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final idLocal = _toInt(registro['id_local']);
      final payload = registro['payload'];
      final fechaCreacionRaw = (registro['fecha_creacion'] ?? '').toString();

      DateTime? fechaCreacion;
      try {
        fechaCreacion = DateTime.parse(fechaCreacionRaw).toUtc();
      } catch (_) {
        fechaCreacion = null;
      }

      if (tabla.isEmpty ||
          operacion.isEmpty ||
          idLocal == null ||
          payload is! Map ||
          fechaCreacion == null) {
        errores++;
        resultados.add({
          'id_local': idLocal,
          'id_remoto': null,
          'tabla': tabla,
          'estado': 'ERROR',
          'detalle':
              'tabla, operacion, payload, id_local y fecha_creacion son obligatorios',
        });
        await _registrarQueueError(
          connection,
          tabla: tabla,
          idLocal: idLocal,
          operacion: operacion,
          payload: payload is Map
              ? Map<String, dynamic>.from(payload)
              : const {},
          fechaCreacion: fechaCreacion ?? DateTime.now().toUtc(),
          error: 'Payload inválido',
        );
        continue;
      }

      final isMasReciente = await _esMasRecienteEnQueue(
        connection,
        tabla: tabla,
        idLocal: idLocal,
        fechaCreacion: fechaCreacion,
      );

      if (!isMasReciente) {
        errores++;
        await _upsertSyncQueue(
          connection,
          tabla: tabla,
          idLocal: idLocal,
          operacion: operacion,
          payload: Map<String, dynamic>.from(payload),
          fechaCreacion: fechaCreacion,
          estado: 'CONFLICTO_DESCARTADO',
          errorMensaje:
              'Conflicto LWW: existe una versión más reciente en el servidor',
        );

        resultados.add({
          'id_local': idLocal,
          'id_remoto': null,
          'tabla': tabla,
          'estado': 'CONFLICTO_DESCARTADO',
        });
        continue;
      }

      if (operacion != 'INSERT') {
        errores++;
        await _registrarQueueError(
          connection,
          tabla: tabla,
          idLocal: idLocal,
          operacion: operacion,
          payload: Map<String, dynamic>.from(payload),
          fechaCreacion: fechaCreacion,
          error: 'Operación no soportada: $operacion',
        );
        resultados.add({
          'id_local': idLocal,
          'id_remoto': null,
          'tabla': tabla,
          'estado': 'ERROR',
          'detalle': 'Operación no soportada: $operacion',
        });
        continue;
      }

      try {
        final idRemoto = await _insertarPorTabla(
          connection,
          usuarioId: usuarioId,
          tabla: tabla,
          payload: Map<String, dynamic>.from(payload),
          fechaCreacion: fechaCreacion,
        );

        await _upsertSyncQueue(
          connection,
          tabla: tabla,
          idLocal: idLocal,
          operacion: operacion,
          payload: {
            ...Map<String, dynamic>.from(payload),
            'id_remoto': idRemoto,
          },
          fechaCreacion: fechaCreacion,
          estado: 'COMPLETADO',
        );

        sincronizados++;
        resultados.add({
          'id_local': idLocal,
          'id_remoto': idRemoto,
          'tabla': tabla,
          'estado': 'OK',
        });
      } catch (error) {
        errores++;
        await _registrarQueueError(
          connection,
          tabla: tabla,
          idLocal: idLocal,
          operacion: operacion,
          payload: Map<String, dynamic>.from(payload),
          fechaCreacion: fechaCreacion,
          error: error.toString(),
        );

        resultados.add({
          'id_local': idLocal,
          'id_remoto': null,
          'tabla': tabla,
          'estado': 'ERROR',
          'detalle': error.toString(),
        });
      }
    }

    return Response.ok(
      jsonEncode({
        'sincronizados': sincronizados,
        'errores': errores,
        'resultados': resultados,
      }),
      headers: _jsonHeaders,
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> pullSync(Request request) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final ultimoSyncRaw = request.url.queryParameters['ultimo_sync'];

  if (ultimoSyncRaw == null || ultimoSyncRaw.trim().isEmpty) {
    return Response(
      400,
      body: jsonEncode({'error': 'ultimo_sync es obligatorio'}),
      headers: _jsonHeaders,
    );
  }

  DateTime ultimoSync;
  try {
    ultimoSync = DateTime.parse(ultimoSyncRaw).toUtc();
  } catch (_) {
    return Response(
      400,
      body: jsonEncode({
        'error': 'ultimo_sync debe ser una fecha ISO-8601 válida',
      }),
      headers: _jsonHeaders,
    );
  }

  final timestampServidor = DateTime.now().toUtc();

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();

    final lotesRows = await connection.query(
      '''
      SELECT
        l.lote_id,
        l.finca_id,
        l.nombre,
        l.tipo_cultivo,
        l.area_m2,
        l.qr_codigo,
        l.fecha_inicio_cultivo,
        l.activo,
        l.sync_estado,
        f.fecha_creacion AS finca_fecha_creacion
      FROM LOTE l
      INNER JOIN FINCA f ON f.finca_id = l.finca_id
      WHERE f.usuario_id = ?
        AND (
          f.fecha_creacion > ?
          OR EXISTS (
            SELECT 1
            FROM SYNC_QUEUE sq
            WHERE sq.tabla_origen = 'LOTE'
              AND sq.registro_id_local = l.lote_id
              AND sq.fecha_creacion > ?
          )
        )
      ORDER BY l.lote_id ASC
      ''',
      [usuarioId, ultimoSync, ultimoSync],
    );

    final registrosRows = await connection.query(
      '''
      SELECT
        ra.registro_id,
        ra.lote_id,
        ra.usuario_id,
        ra.temperatura,
        ra.humedad,
        ra.ph,
        ra.observaciones,
        ra.metodo_captura,
        ra.fecha_hora_registro,
        ra.fecha_hora_guardado,
        ra.sync_estado,
        ra.sync_id_remoto
      FROM REGISTRO_AGRONOMICO ra
      INNER JOIN LOTE l ON l.lote_id = ra.lote_id
      INNER JOIN FINCA f ON f.finca_id = l.finca_id
      WHERE f.usuario_id = ?
        AND (
          ra.fecha_hora_guardado > ?
          OR EXISTS (
            SELECT 1
            FROM SYNC_QUEUE sq
            WHERE sq.tabla_origen = 'REGISTRO_AGRONOMICO'
              AND sq.registro_id_local = ra.registro_id
              AND sq.fecha_creacion > ?
          )
        )
      ORDER BY ra.registro_id ASC
      ''',
      [usuarioId, ultimoSync, ultimoSync],
    );

    final eventosRows = await connection.query(
      '''
      SELECT
        eo.evento_id,
        eo.lote_id,
        eo.usuario_id,
        eo.tipo_labor_id,
        eo.fecha_programada,
        eo.observaciones,
        eo.estado,
        eo.fecha_completado,
        eo.sync_estado
      FROM EVENTO_OPERATIVO eo
      WHERE eo.usuario_id = ?
        AND (
          eo.fecha_programada > ?
          OR (eo.fecha_completado IS NOT NULL AND eo.fecha_completado > ?)
          OR EXISTS (
            SELECT 1
            FROM SYNC_QUEUE sq
            WHERE sq.tabla_origen = 'EVENTO_OPERATIVO'
              AND sq.registro_id_local = eo.evento_id
              AND sq.fecha_creacion > ?
          )
        )
      ORDER BY eo.evento_id ASC
      ''',
      [usuarioId, ultimoSync, ultimoSync, ultimoSync],
    );

    final alertasRows = await connection.query(
      '''
      SELECT
        ag.alerta_id,
        ag.registro_id,
        ag.config_id,
        ag.mensaje,
        ag.fecha_hora,
        ag.leida
      FROM ALERTA_GENERADA ag
      INNER JOIN CONFIGURACION_ALERTA ca ON ca.config_id = ag.config_id
      WHERE ca.usuario_id = ?
        AND ag.fecha_hora > ?
      ORDER BY ag.alerta_id ASC
      ''',
      [usuarioId, ultimoSync],
    );

    final configRows = await connection.query(
      '''
      SELECT
        ca.config_id,
        ca.lote_id,
        ca.usuario_id,
        ca.variable,
        ca.umbral_minimo,
        ca.umbral_maximo,
        ca.activa,
        ca.sync_estado
      FROM CONFIGURACION_ALERTA ca
      WHERE ca.usuario_id = ?
        AND (
          ca.sync_estado <> 'SYNCED'
          OR EXISTS (
            SELECT 1
            FROM SYNC_QUEUE sq
            WHERE sq.tabla_origen = 'CONFIGURACION_ALERTA'
              AND sq.registro_id_local = ca.config_id
              AND sq.fecha_creacion > ?
          )
        )
      ORDER BY ca.config_id ASC
      ''',
      [usuarioId, ultimoSync],
    );

    return Response.ok(
      jsonEncode({
        'timestamp_servidor': timestampServidor.toIso8601String(),
        'cambios': {
          'lotes': lotesRows.map(_mapLote).toList(),
          'registros_agronomicos': registrosRows.map(_mapRegistro).toList(),
          'eventos_operativos': eventosRows.map(_mapEvento).toList(),
          'alertas': alertasRows.map(_mapAlerta).toList(),
          'configuraciones_alerta': configRows.map(_mapConfiguracion).toList(),
        },
      }),
      headers: _jsonHeaders,
    );
  } finally {
    await connection?.close();
  }
}

Future<int> _insertarPorTabla(
  MySqlConnection connection, {
  required int usuarioId,
  required String tabla,
  required Map<String, dynamic> payload,
  required DateTime fechaCreacion,
}) async {
  switch (tabla) {
    case 'REGISTRO_AGRONOMICO':
      return _insertarRegistroAgronomico(
        connection,
        usuarioId: usuarioId,
        payload: payload,
        fechaCreacion: fechaCreacion,
      );
    case 'EVENTO_OPERATIVO':
      return _insertarEventoOperativo(
        connection,
        usuarioId: usuarioId,
        payload: payload,
        fechaCreacion: fechaCreacion,
      );
    default:
      throw StateError('Tabla no soportada para sync push: $tabla');
  }
}

Future<int> _insertarRegistroAgronomico(
  MySqlConnection connection, {
  required int usuarioId,
  required Map<String, dynamic> payload,
  required DateTime fechaCreacion,
}) async {
  final loteId = _toInt(payload['lote_id']);
  if (loteId == null) {
    throw StateError('REGISTRO_AGRONOMICO requiere lote_id');
  }

  await _validarPropiedadLote(connection, usuarioId: usuarioId, loteId: loteId);

  final temperatura = _toDouble(payload['temperatura']);
  final humedad = _toDouble(payload['humedad']);
  final ph = _toDouble(payload['ph']);
  final observaciones = payload['observaciones']?.toString();
  final metodoCaptura = (payload['metodo_captura'] ?? 'MANUAL')
      .toString()
      .trim()
      .toUpperCase();

  final fechaRegistro =
      _parseDateTime(payload['fecha_hora_registro']) ??
      _parseDateTime(payload['fecha_lectura']) ??
      fechaCreacion;
  final fechaGuardado =
      _parseDateTime(payload['fecha_hora_guardado']) ??
      _parseDateTime(payload['fecha_guardado']) ??
      DateTime.now().toUtc();

  final result = await connection.query(
    '''
    INSERT INTO REGISTRO_AGRONOMICO (
      lote_id,
      usuario_id,
      temperatura,
      humedad,
      ph,
      observaciones,
      metodo_captura,
      fecha_hora_registro,
      fecha_hora_guardado,
      sync_estado,
      sync_id_remoto
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      loteId,
      usuarioId,
      temperatura,
      humedad,
      ph,
      observaciones,
      metodoCaptura,
      fechaRegistro,
      fechaGuardado,
      'SYNCED',
      payload['sync_id_remoto']?.toString(),
    ],
  );

  final id = result.insertId;
  if (id == null) {
    throw StateError('No se pudo insertar REGISTRO_AGRONOMICO');
  }
  return id;
}

Future<int> _insertarEventoOperativo(
  MySqlConnection connection, {
  required int usuarioId,
  required Map<String, dynamic> payload,
  required DateTime fechaCreacion,
}) async {
  final loteId = _toInt(payload['lote_id']);
  final tipoLaborId = _toInt(payload['tipo_labor_id']);
  if (loteId == null || tipoLaborId == null) {
    throw StateError('EVENTO_OPERATIVO requiere lote_id y tipo_labor_id');
  }

  await _validarPropiedadLote(connection, usuarioId: usuarioId, loteId: loteId);

  final fechaProgramada =
      _parseDateTime(payload['fecha_programada']) ?? fechaCreacion;
  final observaciones = payload['observaciones']?.toString();
  final estado = (payload['estado'] ?? 'PENDIENTE')
      .toString()
      .trim()
      .toUpperCase();
  final fechaCompletado = _parseDateTime(payload['fecha_completado']);

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
      estado,
      fechaCompletado,
      'SYNCED',
    ],
  );

  final id = result.insertId;
  if (id == null) {
    throw StateError('No se pudo insertar EVENTO_OPERATIVO');
  }
  return id;
}

Future<void> _validarPropiedadLote(
  MySqlConnection connection, {
  required int usuarioId,
  required int loteId,
}) async {
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
    throw StateError('Lote no encontrado o sin permisos');
  }
}

Future<bool> _esMasRecienteEnQueue(
  MySqlConnection connection, {
  required String tabla,
  required int idLocal,
  required DateTime fechaCreacion,
}) async {
  final rows = await connection.query(
    '''
    SELECT fecha_creacion
    FROM SYNC_QUEUE
    WHERE tabla_origen = ? AND registro_id_local = ?
    ORDER BY queue_id DESC
    LIMIT 1
    ''',
    [tabla, idLocal],
  );

  if (rows.isEmpty) {
    return true;
  }

  final fechaExistente = _parseDateTime(rows.first['fecha_creacion']);
  if (fechaExistente == null) {
    return true;
  }

  return !fechaCreacion.isBefore(fechaExistente);
}

Future<void> _registrarQueueError(
  MySqlConnection connection, {
  required String tabla,
  required int? idLocal,
  required String operacion,
  required Map<String, dynamic> payload,
  required DateTime fechaCreacion,
  required String error,
}) async {
  await _upsertSyncQueue(
    connection,
    tabla: tabla,
    idLocal: idLocal ?? -1,
    operacion: operacion,
    payload: payload,
    fechaCreacion: fechaCreacion,
    estado: 'ERROR',
    errorMensaje: error,
    incrementarIntentos: true,
  );
}

Future<void> _upsertSyncQueue(
  MySqlConnection connection, {
  required String tabla,
  required int idLocal,
  required String operacion,
  required Map<String, dynamic> payload,
  required DateTime fechaCreacion,
  required String estado,
  String? errorMensaje,
  bool incrementarIntentos = false,
}) async {
  final current = await connection.query(
    '''
    SELECT queue_id, intentos
    FROM SYNC_QUEUE
    WHERE tabla_origen = ? AND registro_id_local = ?
    ORDER BY queue_id DESC
    LIMIT 1
    ''',
    [tabla, idLocal],
  );

  if (current.isEmpty) {
    await connection.query(
      '''
      INSERT INTO SYNC_QUEUE (
        tabla_origen,
        registro_id_local,
        operacion,
        payload_json,
        fecha_creacion,
        intentos,
        estado,
        error_mensaje
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        tabla,
        idLocal,
        operacion,
        jsonEncode(payload),
        fechaCreacion,
        incrementarIntentos ? 1 : 0,
        estado,
        errorMensaje,
      ],
    );
    return;
  }

  final queueId = _toInt(current.first['queue_id']);
  final intentosActuales = _toInt(current.first['intentos']) ?? 0;
  if (queueId == null) {
    throw StateError('No se pudo leer queue_id para actualizar SYNC_QUEUE');
  }

  await connection.query(
    '''
    UPDATE SYNC_QUEUE
    SET operacion = ?,
        payload_json = ?,
        fecha_creacion = ?,
        intentos = ?,
        estado = ?,
        error_mensaje = ?
    WHERE queue_id = ?
    ''',
    [
      operacion,
      jsonEncode(payload),
      fechaCreacion,
      incrementarIntentos ? intentosActuales + 1 : intentosActuales,
      estado,
      errorMensaje,
      queueId,
    ],
  );
}

Map<String, dynamic> _mapLote(ResultRow row) {
  return {
    'lote_id': _toInt(row['lote_id']),
    'finca_id': _toInt(row['finca_id']),
    'nombre': row['nombre'],
    'tipo_cultivo': row['tipo_cultivo'],
    'area_m2': _toDouble(row['area_m2']),
    'qr_codigo': row['qr_codigo'],
    'fecha_inicio_cultivo': _toIsoString(row['fecha_inicio_cultivo']),
    'activo': _toInt(row['activo']) ?? 1,
    'sync_estado': row['sync_estado'],
    'referencia_fecha': _toIsoString(row['finca_fecha_creacion']),
  };
}

Map<String, dynamic> _mapRegistro(ResultRow row) {
  return {
    'registro_id': _toInt(row['registro_id']),
    'lote_id': _toInt(row['lote_id']),
    'usuario_id': _toInt(row['usuario_id']),
    'temperatura': _toDouble(row['temperatura']),
    'humedad': _toDouble(row['humedad']),
    'ph': _toDouble(row['ph']),
    'observaciones': row['observaciones'],
    'metodo_captura': row['metodo_captura'],
    'fecha_hora_registro': _toIsoString(row['fecha_hora_registro']),
    'fecha_hora_guardado': _toIsoString(row['fecha_hora_guardado']),
    'sync_estado': row['sync_estado'],
    'sync_id_remoto': row['sync_id_remoto'],
  };
}

Map<String, dynamic> _mapEvento(ResultRow row) {
  return {
    'evento_id': _toInt(row['evento_id']),
    'lote_id': _toInt(row['lote_id']),
    'usuario_id': _toInt(row['usuario_id']),
    'tipo_labor_id': _toInt(row['tipo_labor_id']),
    'fecha_programada': _toIsoString(row['fecha_programada']),
    'observaciones': row['observaciones'],
    'estado': row['estado'],
    'fecha_completado': _toIsoString(row['fecha_completado']),
    'sync_estado': row['sync_estado'],
  };
}

Map<String, dynamic> _mapAlerta(ResultRow row) {
  return {
    'alerta_id': _toInt(row['alerta_id']),
    'registro_id': _toInt(row['registro_id']),
    'config_id': _toInt(row['config_id']),
    'mensaje': row['mensaje'],
    'fecha_hora': _toIsoString(row['fecha_hora']),
    'leida': _toInt(row['leida']) ?? 0,
  };
}

Map<String, dynamic> _mapConfiguracion(ResultRow row) {
  return {
    'config_id': _toInt(row['config_id']),
    'lote_id': _toInt(row['lote_id']),
    'usuario_id': _toInt(row['usuario_id']),
    'variable': row['variable'],
    'umbral_minimo': _toDouble(row['umbral_minimo']),
    'umbral_maximo': _toDouble(row['umbral_maximo']),
    'activa': _toInt(row['activa']) ?? 1,
    'sync_estado': row['sync_estado'],
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

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  try {
    return DateTime.parse(value.toString()).toUtc();
  } catch (_) {
    return null;
  }
}

String? _toIsoString(dynamic value) {
  final dateTime = _parseDateTime(value);
  return dateTime?.toIso8601String();
}
