import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'greenpulse.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE proyectos (
        id           INTEGER PRIMARY KEY,
        nombre       TEXT    NOT NULL,
        tipo         TEXT    NOT NULL DEFAULT 'Finca',
        descripcion  TEXT,
        ubicacion_texto TEXT,
        coordenadas  TEXT,
        area_metros_cuadrados REAL,
        activo       INTEGER NOT NULL DEFAULT 1,
        usuario_id   INTEGER,
        creado_en    TEXT,
        total_cultivos INTEGER NOT NULL DEFAULT 0,
        synced_at    TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cultivos (
        id                      INTEGER PRIMARY KEY,
        proyecto_id             INTEGER NOT NULL,
        planta_id               INTEGER,
        planta_nombre           TEXT,
        planta_icono            TEXT,
        variedad                TEXT,
        nombre_lote             TEXT,
        area_m2                 REAL,
        cantidad_plantas        INTEGER,
        fecha_siembra           TEXT,
        fecha_cosecha_estimada  TEXT,
        estado                  TEXT    NOT NULL DEFAULT 'activo',
        notas                   TEXT,
        synced_at               TEXT,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE registros (
        id                  INTEGER PRIMARY KEY,
        cultivo_id          INTEGER NOT NULL,
        temperatura         REAL,
        humedad             REAL,
        ph                  REAL,
        metodo_captura      TEXT,
        fecha_hora_registro TEXT,
        observaciones       TEXT,
        synced_at           TEXT,
        FOREIGN KEY (cultivo_id) REFERENCES cultivos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE alertas (
        id          INTEGER PRIMARY KEY,
        cultivo_id  INTEGER,
        tipo        TEXT,
        mensaje     TEXT    NOT NULL,
        leida       INTEGER NOT NULL DEFAULT 0,
        creada_en   TEXT,
        synced_at   TEXT
      )
    ''');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
