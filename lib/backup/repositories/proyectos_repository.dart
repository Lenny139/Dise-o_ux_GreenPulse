import 'package:sqflite/sqflite.dart';

import '../../models/proyecto.dart';
import '../database/local_database.dart';

class ProyectosRepository {
  ProyectosRepository._();
  static final ProyectosRepository instance = ProyectosRepository._();

  Future<void> guardarProyectos(List<Proyecto> proyectos) async {
    final db = await LocalDatabase.instance.database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final p in proyectos) {
      batch.insert(
        'proyectos',
        {
          'id':                    p.id,
          'nombre':                p.nombre,
          'tipo':                  p.tipo,
          'descripcion':           p.descripcion,
          'ubicacion_texto':       p.ubicacionTexto,
          'coordenadas':           p.coordenadas,
          'area_metros_cuadrados': p.areaMetrosCuadrados,
          'activo':                p.activo ? 1 : 0,
          'usuario_id':            p.usuarioId,
          'creado_en':             p.creadoEn?.toIso8601String(),
          'total_cultivos':        p.totalCultivos,
          'synced_at':             now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Proyecto>> obtenerProyectos() async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'proyectos',
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'creado_en DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Proyecto?> obtenerProyecto(int id) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'proyectos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> eliminarProyecto(int id) async {
    final db = await LocalDatabase.instance.database;
    await db.update(
      'proyectos',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> tieneProyectos() async {
    final db = await LocalDatabase.instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM proyectos WHERE activo = 1'),
    );
    return (count ?? 0) > 0;
  }

  Proyecto _fromRow(Map<String, dynamic> row) {
    return Proyecto(
      id:                   row['id'] as int,
      nombre:               row['nombre'] as String,
      tipo:                 (row['tipo'] as String?) ?? 'Finca',
      descripcion:          row['descripcion'] as String?,
      ubicacionTexto:       row['ubicacion_texto'] as String?,
      coordenadas:          row['coordenadas'] as String?,
      areaMetrosCuadrados:  row['area_metros_cuadrados'] as double?,
      activo:               (row['activo'] as int) == 1,
      usuarioId:            row['usuario_id'] as int?,
      creadoEn:             row['creado_en'] != null
                              ? DateTime.tryParse(row['creado_en'] as String)
                              : null,
      totalCultivos:        (row['total_cultivos'] as int?) ?? 0,
    );
  }
}
