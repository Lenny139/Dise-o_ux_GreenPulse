import 'package:sqflite/sqflite.dart';

import '../../models/cultivo.dart';
import '../database/local_database.dart';

class CultivosRepository {
  CultivosRepository._();
  static final CultivosRepository instance = CultivosRepository._();

  Future<void> guardarCultivos(int proyectoId, List<Cultivo> cultivos) async {
    final db = await LocalDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    // Borrar cultivos previos del proyecto antes de reemplazar
    await db.delete(
      'cultivos',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
    );

    final batch = db.batch();
    for (final c in cultivos) {
      batch.insert(
        'cultivos',
        {
          'id':                     c.id,
          'proyecto_id':            proyectoId,
          'planta_id':              c.plantaId,
          'planta_nombre':          c.plantaNombre,
          'planta_icono':           c.plantaIcono,
          'variedad':               c.variedad,
          'nombre_lote':            c.nombreLote,
          'area_m2':                c.areaM2,
          'cantidad_plantas':       c.cantidadPlantas,
          'fecha_siembra':          c.fechaSiembra?.toIso8601String(),
          'fecha_cosecha_estimada': c.fechaCosechaEstimada?.toIso8601String(),
          'estado':                 c.estado,
          'notas':                  c.notas,
          'synced_at':              now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Cultivo>> obtenerCultivos(int proyectoId) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'cultivos',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      orderBy: 'id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> eliminarCultivo(int id) async {
    final db = await LocalDatabase.instance.database;
    await db.update(
      'cultivos',
      {'estado': 'eliminado'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Cultivo _fromRow(Map<String, dynamic> row) {
    return Cultivo(
      id:                   row['id'] as int,
      proyectoId:           row['proyecto_id'] as int,
      plantaId:             row['planta_id'] as int?,
      plantaNombre:         row['planta_nombre'] as String?,
      plantaIcono:          row['planta_icono'] as String?,
      variedad:             row['variedad'] as String?,
      nombreLote:           row['nombre_lote'] as String?,
      areaM2:               row['area_m2'] as double?,
      cantidadPlantas:      row['cantidad_plantas'] as int?,
      fechaSiembra:         row['fecha_siembra'] != null
                              ? DateTime.tryParse(row['fecha_siembra'] as String)
                              : null,
      fechaCosechaEstimada: row['fecha_cosecha_estimada'] != null
                              ? DateTime.tryParse(
                                  row['fecha_cosecha_estimada'] as String)
                              : null,
      estado:               (row['estado'] as String?) ?? 'activo',
      notas:                row['notas'] as String?,
    );
  }
}
