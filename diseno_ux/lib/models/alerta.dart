class Alerta {
  final int alertaId;
  final String mensaje;
  final DateTime? fechaHora;
  final int leida;

  const Alerta({
    required this.alertaId,
    required this.mensaje,
    this.fechaHora,
    required this.leida,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      alertaId: _toInt(json['alerta_id']) ?? 0,
      mensaje: (json['mensaje'] ?? '').toString(),
      fechaHora: _toDateTime(json['fecha_hora']),
      leida: _toInt(json['leida']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alerta_id': alertaId,
      'mensaje': mensaje,
      'fecha_hora': fechaHora?.toIso8601String(),
      'leida': leida,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
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
