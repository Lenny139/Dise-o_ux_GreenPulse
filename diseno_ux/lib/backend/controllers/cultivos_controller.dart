import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';

Future<Response> listarCultivosPorProyecto(
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

  final queryParams = request.url.queryParameters;
  final page = _toInt(queryParams['page']) ?? 1;
  final limit = _toInt(queryParams['limit']) ?? 20;
  final desde = queryParams['desde'];
  final hasta = queryParams['hasta'];

  if (page < 1 || limit < 1) {
    return Response(
      400,
      body: jsonEncode({'error': 'page y limit deben ser positivos'}),
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

    String whereClause = 'WHERE ra.lote_id = ?';
    final params = <dynamic>[loteId];

    if (desde != null && desde.isNotEmpty) {
      whereClause += ' AND ra.fecha_hora_registro >= ?';
      params.add(desde);
    }

    if (hasta != null && hasta.isNotEmpty) {
      whereClause += ' AND ra.fecha_hora_registro <= ?';
      params.add(hasta);
    }

    final totalRows = await connection.query(
      'SELECT COUNT(*) AS total FROM REGISTRO_AGRONOMICO ra $whereClause',
      params,
    );
    final total = _toInt(totalRows.first['total']) ?? 0;

    final offset = (page - 1) * limit;
    final registros = await connection.query(
      '''
      SELECT
        ra.registro_id,
        ra.temperatura,
        ra.humedad,
        ra.ph,
        ra.metodo_captura,
        ra.fecha_hora_registro,
        ra.observaciones
      FROM REGISTRO_AGRONOMICO ra
      $whereClause
      ORDER BY ra.fecha_hora_registro DESC
      LIMIT ? OFFSET ?
      ''',
      [...params, limit, offset],
    );

    final registrosList = registros
        .map(
          (row) => {
            'registro_id': _toInt(row['registro_id']),
            'temperatura': _toDouble(row['temperatura']),
            'humedad': _toDouble(row['humedad']),
            'ph': _toDouble(row['ph']),
            'metodo_captura': row['metodo_captura'],
            'fecha_hora_registro': _toIsoString(row['fecha_hora_registro']),
            'observaciones': row['observaciones'],
          },
        )
        .toList();

    return Response.ok(
      jsonEncode({'total': total, 'pagina': page, 'registros': registrosList}),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> crearCultivo(Request request, String proyectoId) async {
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

  final temperatura = _toDouble(data['temperatura_celsius']);
  final humedad = _toDouble(data['humedad_relativa']);
  final ph = _toDouble(data['ph_suelo']);
  final metodoIngreso = (data['metodo_ingreso'] ?? 'MANUAL').toString().trim();
  final fechaLectura = (data['fecha_lectura'] ?? '').toString().trim();
  final observaciones = (data['observaciones'] ?? '').toString().trim();

  if (temperatura == null || humedad == null || ph == null) {
    return Response(
      400,
      body: jsonEncode({
        'error':
            'temperatura_celsius, humedad_relativa y ph_suelo son obligatorios',
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  if (temperatura < -10 || temperatura > 60) {
    return Response(
      422,
      body: jsonEncode({
        'error': 'Valor fuera de rango',
        'campo': 'temperatura',
        'valor': temperatura,
        'rango_valido': '-10 a 60',
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  if (humedad < 0 || humedad > 100) {
    return Response(
      422,
      body: jsonEncode({
        'error': 'Valor fuera de rango',
        'campo': 'humedad',
        'valor': humedad,
        'rango_valido': '0 a 100',
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  if (ph < 0 || ph > 14) {
    return Response(
      422,
      body: jsonEncode({
        'error': 'Valor fuera de rango',
        'campo': 'ph',
        'valor': ph,
        'rango_valido': '0 a 14',
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
        body: jsonEncode({'error': 'Proyecto no encontrado'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final now = DateTime.now().toUtc();
    final fechaRegistro = fechaLectura.isNotEmpty
        ? DateTime.parse(fechaLectura)
        : now;

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
        metodoIngreso,
        fechaRegistro,
        now,
        'PENDING',
        null,
      ],
    );

    final registroId = result.insertId;
    if (registroId == null) {
      throw StateError('No se pudo insertar el registro agronómico');
    }

    final alertas = await _checkAlertas(
      connection,
      registroId,
      loteId,
      usuarioId,
      temperatura,
      humedad,
      ph,
    );

    return Response(
      201,
      body: jsonEncode({
        'registro_id': registroId,
        'mensaje': 'Registro guardado',
        'alertas_generadas': alertas,
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> obtenerCultivo(Request request, String cultivoId) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final registroId = int.tryParse(cultivoId.trim());

  if (registroId == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'cultivo_id inválido'}),
      headers: {'content-type': 'application/json'},
    );
  }

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();

    final rows = await connection.query(
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
      WHERE ra.registro_id = ? AND f.usuario_id = ?
      LIMIT 1
      ''',
      [registroId, usuarioId],
    );

    if (rows.isEmpty) {
      return Response(
        404,
        body: jsonEncode({'error': 'Cultivo no encontrado'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final row = rows.first;
    return Response.ok(
      jsonEncode({
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
      }),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> actualizarCultivo(Request request, String cultivoId) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final registroId = int.tryParse(cultivoId.trim());

  if (registroId == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'cultivo_id inválido'}),
      headers: {'content-type': 'application/json'},
    );
  }

  final body = await request.readAsString();
  final Map<String, dynamic> data = jsonDecode(body) as Map<String, dynamic>;
  final observaciones = (data['observaciones'] ?? '').toString().trim();

  MySqlConnection? connection;
  try {
    connection = await openDatabaseConnection();

    final ownership = await connection.query(
      '''
      SELECT ra.registro_id
      FROM REGISTRO_AGRONOMICO ra
      INNER JOIN LOTE l ON l.lote_id = ra.lote_id
      INNER JOIN FINCA f ON f.finca_id = l.finca_id
      WHERE ra.registro_id = ? AND f.usuario_id = ?
      LIMIT 1
      ''',
      [registroId, usuarioId],
    );

    if (ownership.isEmpty) {
      return Response(
        404,
        body: jsonEncode({'error': 'Cultivo no encontrado'}),
        headers: {'content-type': 'application/json'},
      );
    }

    await connection.query(
      'UPDATE REGISTRO_AGRONOMICO SET observaciones = ? WHERE registro_id = ?',
      [observaciones, registroId],
    );

    return Response.ok(
      jsonEncode({'mensaje': 'Actualizado'}),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<Response> eliminarCultivo(Request request, String cultivoId) async {
  final usuarioId = _usuarioIdDesdeRequest(request);
  final registroId = int.tryParse(cultivoId.trim());

  if (registroId == null) {
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
      SELECT ra.registro_id
      FROM REGISTRO_AGRONOMICO ra
      INNER JOIN LOTE l ON l.lote_id = ra.lote_id
      INNER JOIN FINCA f ON f.finca_id = l.finca_id
      WHERE ra.registro_id = ? AND f.usuario_id = ?
      LIMIT 1
      ''',
      [registroId, usuarioId],
    );

    if (ownership.isEmpty) {
      return Response(
        404,
        body: jsonEncode({'error': 'Cultivo no encontrado'}),
        headers: {'content-type': 'application/json'},
      );
    }

    await connection.query(
      'DELETE FROM REGISTRO_AGRONOMICO WHERE registro_id = ?',
      [registroId],
    );

    return Response.ok(
      jsonEncode({'mensaje': 'Registro eliminado'}),
      headers: {'content-type': 'application/json'},
    );
  } finally {
    await connection?.close();
  }
}

Future<int> _checkAlertas(
  MySqlConnection connection,
  int registroId,
  int loteId,
  int usuarioId,
  double temperatura,
  double humedad,
  double ph,
) async {
  final configuraciones = await connection.query(
    '''
    SELECT
      config_id,
      variable,
      umbral_minimo,
      umbral_maximo
    FROM CONFIGURACION_ALERTA
    WHERE lote_id = ? AND usuario_id = ? AND activa = 1
    ''',
    [loteId, usuarioId],
  );

  int alertasCreadas = 0;
  final now = DateTime.now().toUtc();

  for (final config in configuraciones) {
    final variable = config['variable'].toString();
    final umbralMinimo = _toDouble(config['umbral_minimo']);
    final umbralMaximo = _toDouble(config['umbral_maximo']);
    final configId = _toInt(config['config_id']);

    if (configId == null) continue;

    bool debeAlerta = false;
    String mensaje = '';

    if (variable == 'TEMPERATURA') {
      if ((umbralMinimo != null && temperatura < umbralMinimo) ||
          (umbralMaximo != null && temperatura > umbralMaximo)) {
        debeAlerta = true;
        mensaje = 'Temperatura fuera de rango: $temperatura°C';
      }
    } else if (variable == 'HUMEDAD') {
      if ((umbralMinimo != null && humedad < umbralMinimo) ||
          (umbralMaximo != null && humedad > umbralMaximo)) {
        debeAlerta = true;
        mensaje = 'Humedad fuera de rango: $humedad%';
      }
    } else if (variable == 'PH') {
      if ((umbralMinimo != null && ph < umbralMinimo) ||
          (umbralMaximo != null && ph > umbralMaximo)) {
        debeAlerta = true;
        mensaje = 'pH fuera de rango: $ph';
      }
    }

    if (debeAlerta) {
      await connection.query(
        '''
        INSERT INTO ALERTA_GENERADA (
          registro_id,
          config_id,
          mensaje,
          fecha_hora,
          leida
        ) VALUES (?, ?, ?, ?, ?)
        ''',
        [registroId, configId, mensaje, now, 0],
      );
      alertasCreadas++;
    }
  }

  return alertasCreadas;
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
