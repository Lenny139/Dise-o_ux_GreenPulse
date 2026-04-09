class Lote {
  final int loteId;
  final String nombre;
  final String? tipoCultivo;
  final double? areaM2;
  final String? qrCodigo;
  final int activo;
  final DateTime? fechaInicioCultivo;

  const Lote({
    required this.loteId,
    required this.nombre,
    this.tipoCultivo,
    this.areaM2,
    this.qrCodigo,
    required this.activo,
    this.fechaInicioCultivo,
  });

  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      loteId: _toInt(json['lote_id']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      tipoCultivo: json['tipo_cultivo']?.toString(),
      areaM2: _toDouble(json['area_m2']),
      qrCodigo: json['qr_codigo']?.toString(),
      activo: _toInt(json['activo']) ?? 1,
      fechaInicioCultivo: _toDateTime(json['fecha_inicio_cultivo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lote_id': loteId,
      'nombre': nombre,
      'tipo_cultivo': tipoCultivo,
      'area_m2': areaM2,
      'qr_codigo': qrCodigo,
      'activo': activo,
      'fecha_inicio_cultivo': fechaInicioCultivo?.toIso8601String(),
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
