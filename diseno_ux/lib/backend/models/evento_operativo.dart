import 'model_utils.dart';

class EventoOperativo {
  static const String tableName = 'EVENTO_OPERATIVO';

  final int? eventoId;
  final int loteId;
  final int usuarioId;
  final int tipoLaborId;
  final DateTime fechaProgramada;
  final String? observaciones;
  final String estado;
  final DateTime? fechaCompletado;
  final String syncEstado;

  const EventoOperativo({
    this.eventoId,
    required this.loteId,
    required this.usuarioId,
    required this.tipoLaborId,
    required this.fechaProgramada,
    this.observaciones,
    this.estado = 'PENDIENTE',
    this.fechaCompletado,
    required this.syncEstado,
  });

  factory EventoOperativo.fromMap(Map<String, dynamic> map) {
    return EventoOperativo(
      eventoId: map['evento_id'] as int?,
      loteId: map['lote_id'] as int,
      usuarioId: map['usuario_id'] as int,
      tipoLaborId: map['tipo_labor_id'] as int,
      fechaProgramada: parseDate(map['fecha_programada'])!,
      observaciones: map['observaciones'] as String?,
      estado: (map['estado'] as String?) ?? 'PENDIENTE',
      fechaCompletado: parseDateTime(map['fecha_completado']),
      syncEstado: map['sync_estado'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'evento_id': eventoId,
      'lote_id': loteId,
      'usuario_id': usuarioId,
      'tipo_labor_id': tipoLaborId,
      'fecha_programada': fechaProgramada,
      'observaciones': observaciones,
      'estado': estado,
      'fecha_completado': fechaCompletado,
      'sync_estado': syncEstado,
    };
  }
}
