import 'model_utils.dart';

class ExportacionHistorial {
  static const String tableName = 'EXPORTACION_HISTORIAL';

  final int? exportacionId;
  final int usuarioId;
  final int loteId;
  final String formato;
  final DateTime fechaDesde;
  final DateTime fechaHasta;
  final DateTime fechaGeneracion;
  final String? rutaArchivoLocal;

  const ExportacionHistorial({
    this.exportacionId,
    required this.usuarioId,
    required this.loteId,
    required this.formato,
    required this.fechaDesde,
    required this.fechaHasta,
    required this.fechaGeneracion,
    this.rutaArchivoLocal,
  });

  factory ExportacionHistorial.fromMap(Map<String, dynamic> map) {
    return ExportacionHistorial(
      exportacionId: map['exportacion_id'] as int?,
      usuarioId: map['usuario_id'] as int,
      loteId: map['lote_id'] as int,
      formato: map['formato'] as String,
      fechaDesde: parseDate(map['fecha_desde'])!,
      fechaHasta: parseDate(map['fecha_hasta'])!,
      fechaGeneracion: parseDateTime(map['fecha_generacion'])!,
      rutaArchivoLocal: map['ruta_archivo_local'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exportacion_id': exportacionId,
      'usuario_id': usuarioId,
      'lote_id': loteId,
      'formato': formato,
      'fecha_desde': fechaDesde,
      'fecha_hasta': fechaHasta,
      'fecha_generacion': fechaGeneracion,
      'ruta_archivo_local': rutaArchivoLocal,
    };
  }
}
