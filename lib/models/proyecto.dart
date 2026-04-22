class Proyecto {
  final int id;
  final String nombre;
  final String tipo;
  final String? descripcion;
  final String? ubicacionTexto;
  final String? coordenadas;
  final double? areaMetrosCuadrados;
  final bool activo;
  final int? usuarioId;
  final DateTime? creadoEn;
  final int totalCultivos;

  const Proyecto({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.ubicacionTexto,
    this.coordenadas,
    this.areaMetrosCuadrados,
    required this.activo,
    this.usuarioId,
    this.creadoEn,
    this.totalCultivos = 0,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: _toInt(json['id']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'Finca').toString(),
      descripcion: json['descripcion']?.toString(),
      ubicacionTexto: json['ubicacion_texto']?.toString(),
      coordenadas: json['coordenadas']?.toString(),
      areaMetrosCuadrados: _toDouble(json['area_metros_cuadrados']),
      activo: _toBool(json['activo']),
      usuarioId: _toInt(json['usuario_id']),
      creadoEn: _toDateTime(json['creado_en']),
      totalCultivos: _toInt(json['total_cultivos']) ?? 0,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static bool _toBool(dynamic v) {
    if (v == null) return true;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v.toString().toLowerCase() == 'true';
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}
