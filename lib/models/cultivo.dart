class Cultivo {
  final int id;
  final int proyectoId;
  final int? plantaId;
  final String? plantaNombre;  // Ej: "Tomate", "Café"
  final String? plantaIcono;
  final String? variedad;
  final String? nombreLote;
  final double? areaM2;
  final int? cantidadPlantas;
  final DateTime? fechaSiembra;
  final DateTime? fechaCosechaEstimada;
  final String estado;          // "activo" | "cosechado" | "abandonado"
  final String? notas;

  const Cultivo({
    required this.id,
    required this.proyectoId,
    this.plantaId,
    this.plantaNombre,
    this.plantaIcono,
    this.variedad,
    this.nombreLote,
    this.areaM2,
    this.cantidadPlantas,
    this.fechaSiembra,
    this.fechaCosechaEstimada,
    this.estado = 'activo',
    this.notas,
  });

  /// Nombre legible: prefiere plantaNombre, sino nombreLote, sino "Sin nombre"
  String get displayName =>
      plantaNombre?.isNotEmpty == true
      ? plantaNombre!
      : nombreLote?.isNotEmpty == true
          ? nombreLote!
          : 'Sin nombre';

  factory Cultivo.fromJson(Map<String, dynamic> json) {
    return Cultivo(
      id: _toInt(json['id']) ?? 0,
      proyectoId: _toInt(json['proyecto_id']) ?? 0,
      plantaId: _toInt(json['planta_id']),
      plantaNombre: json['planta_nombre']?.toString(),
      plantaIcono: json['planta_icono']?.toString(),
      variedad: json['variedad']?.toString(),
      nombreLote: json['nombre_lote']?.toString(),
      areaM2: _toDouble(json['area_m2']),
      cantidadPlantas: _toInt(json['cantidad_plantas']),
      fechaSiembra: _toDateTime(json['fecha_siembra']),
      fechaCosechaEstimada: _toDateTime(json['fecha_cosecha_estimada']),
      estado: (json['estado'] ?? 'activo').toString(),
      notas: json['notas']?.toString(),
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
