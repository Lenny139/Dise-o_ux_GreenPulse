import 'model_utils.dart';

class Lote {
  static const String tableName = 'LOTE';

  final int? loteId;
  final int fincaId;
  final String nombre;
  final String? tipoCultivo;
  final double? areaM2;
  final String qrCodigo;
  final List<int>? qrImagenBase64;
  final DateTime? fechaInicioCultivo;
  final int activo;
  final String syncEstado;

  const Lote({
    this.loteId,
    required this.fincaId,
    required this.nombre,
    this.tipoCultivo,
    this.areaM2,
    required this.qrCodigo,
    this.qrImagenBase64,
    this.fechaInicioCultivo,
    required this.activo,
    required this.syncEstado,
  });

  factory Lote.fromMap(Map<String, dynamic> map) {
    return Lote(
      loteId: map['lote_id'] as int?,
      fincaId: map['finca_id'] as int,
      nombre: map['nombre'] as String,
      tipoCultivo: map['tipo_cultivo'] as String?,
      areaM2: (map['area_m2'] as num?)?.toDouble(),
      qrCodigo: map['qr_codigo'] as String,
      qrImagenBase64: (map['qr_imagen_base64'] as List<int>?),
      fechaInicioCultivo: parseDate(map['fecha_inicio_cultivo']),
      activo: map['activo'] as int,
      syncEstado: map['sync_estado'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lote_id': loteId,
      'finca_id': fincaId,
      'nombre': nombre,
      'tipo_cultivo': tipoCultivo,
      'area_m2': areaM2,
      'qr_codigo': qrCodigo,
      'qr_imagen_base64': qrImagenBase64,
      'fecha_inicio_cultivo': fechaInicioCultivo,
      'activo': activo,
      'sync_estado': syncEstado,
    };
  }
}
