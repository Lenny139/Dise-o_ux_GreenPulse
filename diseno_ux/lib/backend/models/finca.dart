import 'model_utils.dart';

class Finca {
  static const String tableName = 'FINCA';

  final int? fincaId;
  final int usuarioId;
  final String nombre;
  final String? ubicacionDescripcion;
  final double? latitud;
  final double? longitud;
  final DateTime fechaCreacion;
  final String syncEstado;

  const Finca({
    this.fincaId,
    required this.usuarioId,
    required this.nombre,
    this.ubicacionDescripcion,
    this.latitud,
    this.longitud,
    required this.fechaCreacion,
    required this.syncEstado,
  });

  factory Finca.fromMap(Map<String, dynamic> map) {
    return Finca(
      fincaId: map['finca_id'] as int?,
      usuarioId: map['usuario_id'] as int,
      nombre: map['nombre'] as String,
      ubicacionDescripcion: map['ubicacion_descripcion'] as String?,
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      fechaCreacion: parseDateTime(map['fecha_creacion'])!,
      syncEstado: map['sync_estado'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'finca_id': fincaId,
      'usuario_id': usuarioId,
      'nombre': nombre,
      'ubicacion_descripcion': ubicacionDescripcion,
      'latitud': latitud,
      'longitud': longitud,
      'fecha_creacion': fechaCreacion,
      'sync_estado': syncEstado,
    };
  }
}
