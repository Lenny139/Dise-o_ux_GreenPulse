import 'package:sqflite/sqflite.dart';

import '../../models/alerta.dart';
import '../database/local_database.dart';

class AlertasRepository {
  AlertasRepository._();
  static final AlertasRepository instance = AlertasRepository._();

  Future<void> guardarAlertas(List<Alerta> alertas) async {
    final db = await LocalDatabase.instance.database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final a in alertas) {
      batch.insert(
        'alertas',
        {
          'id':         a.alertaId,
          'mensaje':    a.mensaje,
          'leida':      a.leida,
          'creada_en':  a.fechaHora?.toIso8601String(),
          'synced_at':  now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Alerta>> obtenerAlertas() async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'alertas',
      orderBy: 'creada_en DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Alerta?> obtenerUltimaAlerta() async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'alertas',
      orderBy: 'creada_en DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> marcarLeida(int alertaId) async {
    final db = await LocalDatabase.instance.database;
    await db.update(
      'alertas',
      {'leida': 1},
      where: 'id = ?',
      whereArgs: [alertaId],
    );
  }

  Alerta _fromRow(Map<String, dynamic> row) {
    return Alerta(
      alertaId: row['id'] as int,
      mensaje:  row['mensaje'] as String,
      leida:    (row['leida'] as int?) ?? 0,
      fechaHora: row['creada_en'] != null
                   ? DateTime.tryParse(row['creada_en'] as String)
                   : null,
    );
  }
}
