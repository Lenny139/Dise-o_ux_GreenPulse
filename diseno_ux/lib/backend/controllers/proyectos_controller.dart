import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../config/database.dart';

const _uuid = Uuid();

Future<Response> listarProyectos(Request request) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  MySqlConnection? connection;

  try {
    connection = await openDatabaseConnection();

    final results = await connection.query(
      '''
      SELECT
        f.finca_id,
        f.nombre,
        f.ubicacion_descripcion,
        f.latitud,
        f.longitud,
        f.fecha_creacion,
        COALESCE(SUM(CASE WHEN l.activo = 1 THEN 1 ELSE 0 END), 0) AS total_lotes
      FROM FINCA f
      LEFT JOIN LOTE l ON l.finca_id = f.finca_id
      WHERE f.usuario_id = ?
      GROUP BY f.finca_id, f.nombre, f.ubicacion_descripcion, f.latitud, f.longitud, f.fecha_creacion
      ORDER BY f.fecha_creacion DESC
      ''',
      [usuarioId],
    );

    final proyectos = results
        .map(
          (row) => {
            'finca_id': _toInt(row['finca_id']),
            'nombre': row['nombre'],
            'ubicacion_descripcion': row['ubicacion_descripcion'],
            'latitud': _toDouble(row['latitud']),
            'longitud': _toDouble(row['longitud']),
            'fecha_creacion': _toIsoString(row['fecha_creacion']),
            'total_lotes': _toInt(row['total_lotes']) ?? 0,
          },
        )
        .toList();

    return Response.ok(
      jsonEncode({'proyectos': proyectos}),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> crearProyecto(Request request) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final body = await request.readAsString();
  final Map<String, dynamic> data = jsonDecode(body) as Map<String, dynamic>;

  final nombre = (data['nombre'] ?? '').toString().trim();
  final tipoCultivo = (data['tipo_cultivo'] ?? '').toString().trim();
  final coordenadas = (data['coordenadas'] ?? '').toString().trim();
  final areaMetrosCuadrados = _toDouble(data['area_metros_cuadrados']);

  if (nombre.isEmpty ||
      tipoCultivo.isEmpty ||
      coordenadas.isEmpty ||
      areaMetrosCuadrados == null) {
    return Response(
      400,
      body: jsonEncode({
        'error':
            'nombre, tipo_cultivo, area_metros_cuadrados y coordenadas son obligatorios',
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  final coordenadasSeparadas = coordenadas.split(',');
  if (coordenadasSeparadas.length < 2) {
    return Response(
      400,
      body: jsonEncode({
        'error': 'coordenadas debe tener formato "latitud, longitud"',
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  final latitud = double.tryParse(coordenadasSeparadas[0].trim());
  final longitud = double.tryParse(coordenadasSeparadas[1].trim());

  if (latitud == null || longitud == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'No se pudieron interpretar las coordenadas'}),
      headers: {'content-type': 'application/json'},
    );
  }

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();
    await connection.query('START TRANSACTION');

    final now = DateTime.now().toUtc();

    final fincaResult = await connection.query(
      '''
      INSERT INTO FINCA (
        usuario_id,
        nombre,
        ubicacion_descripcion,
        latitud,
        longitud,
        fecha_creacion,
        sync_estado
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [usuarioId, nombre, coordenadas, latitud, longitud, now, 'PENDING'],
    );

    final fincaId = fincaResult.insertId;
    if (fincaId == null) {
      throw StateError('No se pudo crear la finca');
    }

    final qrCodigo = _uuid.v4();
    final loteResult = await connection.query(
      '''
      INSERT INTO LOTE (
        finca_id,
        nombre,
        tipo_cultivo,
        area_m2,
        qr_codigo,
        qr_imagen_base64,
        fecha_inicio_cultivo,
        activo,
        sync_estado
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        fincaId,
        nombre,
        tipoCultivo,
        areaMetrosCuadrados,
        qrCodigo,
        null,
        null,
        1,
        'PENDING',
      ],
    );

    final loteId = loteResult.insertId;
    if (loteId == null) {
      throw StateError('No se pudo crear el lote');
    }

    await connection.query('COMMIT');

    return Response(
      201,
      body: jsonEncode({
        'proyecto_id': 'lote_$loteId',
        'nombre': nombre,
        'estado': 'activo',
        'fecha_creacion': now.toIso8601String(),
        'qr_codigo': qrCodigo,
      }),
      headers: {'content-type': 'application/json'},
    );
  } catch (error) {
    if (connection != null) {
      await connection.query('ROLLBACK');
    }
    return Response(
      500,
      body: jsonEncode({
        'error': 'No se pudo crear el proyecto',
        'detalle': error.toString(),
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> obtenerProyectoPorId(
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

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();

    final loteRows = await connection.query(
      '''
      SELECT
        l.lote_id,
        l.nombre,
        l.activo,
        l.tipo_cultivo,
        l.area_m2,
        l.qr_codigo,
        f.fecha_creacion
      FROM LOTE l
      INNER JOIN FINCA f ON f.finca_id = l.finca_id
      WHERE l.lote_id = ? AND f.usuario_id = ?
      LIMIT 1
      ''',
      [loteId, usuarioId],
    );

    if (loteRows.isEmpty) {
      return Response(
        404,
        body: jsonEncode({'error': 'Proyecto no encontrado'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final lote = loteRows.first;

    final registrosRows = await connection.query(
      '''
      SELECT
        registro_id,
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
      FROM REGISTRO_AGRONOMICO
      WHERE lote_id = ?
      ORDER BY fecha_hora_registro DESC
      LIMIT 5
      ''',
      [loteId],
    );

    final ultimosRegistros = registrosRows
        .map(
          (row) => {
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
          },
        )
        .toList();

    final estaActivo = await _esProyectoActivo(connection, loteId);

    return Response.ok(
      jsonEncode({
        'id': 'lote_${_toInt(lote['lote_id'])}',
        'nombre': lote['nombre'],
        'estado': estaActivo ? 'activo' : 'inactivo',
        'tipo_cultivo': lote['tipo_cultivo'],
        'area_m2': _toDouble(lote['area_m2']),
        'qr_codigo': lote['qr_codigo'],
        'fecha_creacion': _toIsoString(lote['fecha_creacion']),
        'ultimos_registros': ultimosRegistros,
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> actualizarProyecto(Request request, String proyectoId) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final loteId = _extraerLoteId(proyectoId);
  if (loteId == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'proyecto_id inválido'}),
      headers: {'content-type': 'application/json'},
    );
  }

  final body = await request.readAsString();
  final Map<String, dynamic> data = jsonDecode(body) as Map<String, dynamic>;

  final nombre = data['nombre']?.toString().trim();
  final tipoCultivo = data['tipo_cultivo']?.toString().trim();
  final areaM2 = _toDouble(data['area_m2']);

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

    final fields = <String>[];
    final values = <dynamic>[];

    if (nombre != null && nombre.isNotEmpty) {
      fields.add('nombre = ?');
      values.add(nombre);
    }
    if (tipoCultivo != null && tipoCultivo.isNotEmpty) {
      fields.add('tipo_cultivo = ?');
      values.add(tipoCultivo);
    }
    if (areaM2 != null) {
      fields.add('area_m2 = ?');
      values.add(areaM2);
    }

    if (fields.isEmpty) {
      return Response(
        400,
        body: jsonEncode({
          'error': 'No se proporcionaron campos para actualizar',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    values.add(loteId);

    await connection.query(
      'UPDATE LOTE SET ${fields.join(', ')} WHERE lote_id = ?',
      values,
    );

    final updatedRows = await connection.query(
      '''
      SELECT
        l.lote_id,
        l.nombre,
        l.tipo_cultivo,
        l.area_m2,
        l.qr_codigo,
        l.activo,
        f.fecha_creacion
      FROM LOTE l
      INNER JOIN FINCA f ON f.finca_id = l.finca_id
      WHERE l.lote_id = ?
      LIMIT 1
      ''',
      [loteId],
    );

    final updated = updatedRows.first;
    final proyecto = {
      'id': 'lote_${_toInt(updated['lote_id'])}',
      'nombre': updated['nombre'],
      'estado': _toInt(updated['activo']) == 1 ? 'activo' : 'inactivo',
      'tipo_cultivo': updated['tipo_cultivo'],
      'area_m2': _toDouble(updated['area_m2']),
      'qr_codigo': updated['qr_codigo'],
      'fecha_creacion': _toIsoString(updated['fecha_creacion']),
    };

    return Response.ok(
      jsonEncode({'mensaje': 'Proyecto actualizado', 'proyecto': proyecto}),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> desactivarProyecto(Request request, String proyectoId) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final loteId = _extraerLoteId(proyectoId);
  if (loteId == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'proyecto_id inválido'}),
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

    await connection.query('UPDATE LOTE SET activo = 0 WHERE lote_id = ?', [
      loteId,
    ]);

    return Response.ok(
      jsonEncode({'mensaje': 'Proyecto desactivado correctamente'}),
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

Future<bool> _esProyectoActivo(MySqlConnection connection, int loteId) async {
  final rows = await connection.query(
    '''
    SELECT COUNT(*) AS total
    FROM REGISTRO_AGRONOMICO
    WHERE lote_id = ?
      AND fecha_hora_registro >= (NOW() - INTERVAL 30 DAY)
    ''',
    [loteId],
  );

  final registrosRecientes = rows.first['total'];
  final cantidad = _toInt(registrosRecientes) ?? 0;

  final loteRows = await connection.query(
    'SELECT activo FROM LOTE WHERE lote_id = ? LIMIT 1',
    [loteId],
  );

  if (loteRows.isEmpty) {
    return false;
  }

  return _toInt(loteRows.first['activo']) == 1 && cantidad > 0;
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
