import 'package:sqflite/sqflite.dart';

import '../../models/registro_agronomico.dart';
import '../database/local_database.dart';

class RegistrosRepository {
  RegistrosRepository._();
  static final RegistrosRepository instance = RegistrosRepository._();

  Future<void> guardarRegistros(
    int cultivoId,
    List<RegistroAgronomico> registros,
  ) async {
    final db = await LocalDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    // Reemplazar registros del cultivo
    await db.delete(
      'registros',
      where: 'cultivo_id = ?',
      whereArgs: [cultivoId],
    );

    final batch = db.batch();
    for (final r in registros) {
      batch.insert(
        'registros',
        {
          'id':                  r.registroId,
          'cultivo_id':          cultivoId,
          'temperatura':         r.temperatura,
          'humedad':             r.humedad,
          'ph':                  r.ph,
          'metodo_captura':      r.metodoCaptura,
          'fecha_hora_registro': r.fechaHoraRegistro?.toIso8601String(),
          'observaciones':       r.observaciones,
          'synced_at':           now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> guardarRegistro(
    int cultivoId,
    RegistroAgronomico registro,
  ) async {
    final db = await LocalDatabase.instance.database;
    await db.insert(
      'registros',
      {
        'id':                  registro.registroId,
        'cultivo_id':          cultivoId,
        'temperatura':         registro.temperatura,
        'humedad':             registro.humedad,
        'ph':                  registro.ph,
        'metodo_captura':      registro.metodoCaptura,
        'fecha_hora_registro': registro.fechaHoraRegistro?.toIso8601String(),
        'observaciones':       registro.observaciones,
        'synced_at':           DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RegistroAgronomico>> obtenerRegistros(int cultivoId) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'registros',
      where: 'cultivo_id = ?',
      whereArgs: [cultivoId],
      orderBy: 'fecha_hora_registro DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<RegistroAgronomico?> obtenerUltimoRegistro(int cultivoId) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'registros',
      where: 'cultivo_id = ?',
      whereArgs: [cultivoId],
      orderBy: 'fecha_hora_registro DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  RegistroAgronomico _fromRow(Map<String, dynamic> row) {
    return RegistroAgronomico(
      registroId:       row['id'] as int,
      temperatura:      row['temperatura'] as double?,
      humedad:          row['humedad'] as double?,
      ph:               row['ph'] as double?,
      metodoCaptura:    row['metodo_captura'] as String?,
      fechaHoraRegistro: row['fecha_hora_registro'] != null
                           ? DateTime.tryParse(
                               row['fecha_hora_registro'] as String)
                           : null,
      observaciones:    row['observaciones'] as String?,
    );
  }
}
