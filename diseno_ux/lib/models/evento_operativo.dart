class EventoOperativo {
  final int eventoId;
  final int loteId;
  final int tipoLaborId;
  final DateTime? fechaProgramada;
  final String estado;
  final String? observaciones;

  const EventoOperativo({
    required this.eventoId,
    required this.loteId,
    required this.tipoLaborId,
    this.fechaProgramada,
    required this.estado,
    this.observaciones,
  });

  factory EventoOperativo.fromJson(Map<String, dynamic> json) {
    return EventoOperativo(
      eventoId: _toInt(json['evento_id']) ?? 0,
      loteId: _toInt(json['lote_id']) ?? 0,
      tipoLaborId: _toInt(json['tipo_labor_id']) ?? 0,
      fechaProgramada: _toDateTime(json['fecha_programada']),
      estado: (json['estado'] ?? 'PENDIENTE').toString(),
      observaciones: json['observaciones']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'evento_id': eventoId,
      'lote_id': loteId,
      'tipo_labor_id': tipoLaborId,
      'fecha_programada': fechaProgramada?.toIso8601String(),
      'estado': estado,
      'observaciones': observaciones,
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
