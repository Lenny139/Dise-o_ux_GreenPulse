import 'model_utils.dart';

class SyncQueue {
  static const String tableName = 'SYNC_QUEUE';

  final int? queueId;
  final String tablaOrigen;
  final int registroIdLocal;
  final String operacion;
  final String payloadJson;
  final DateTime fechaCreacion;
  final int intentos;
  final String estado;
  final String? errorMensaje;

  const SyncQueue({
    this.queueId,
    required this.tablaOrigen,
    required this.registroIdLocal,
    required this.operacion,
    required this.payloadJson,
    required this.fechaCreacion,
    this.intentos = 0,
    this.estado = 'PENDIENTE',
    this.errorMensaje,
  });

  factory SyncQueue.fromMap(Map<String, dynamic> map) {
    return SyncQueue(
      queueId: map['queue_id'] as int?,
      tablaOrigen: map['tabla_origen'] as String,
      registroIdLocal: map['registro_id_local'] as int,
      operacion: map['operacion'] as String,
      payloadJson: map['payload_json'] as String,
      fechaCreacion: parseDateTime(map['fecha_creacion'])!,
      intentos: (map['intentos'] as int?) ?? 0,
      estado: (map['estado'] as String?) ?? 'PENDIENTE',
      errorMensaje: map['error_mensaje'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'queue_id': queueId,
      'tabla_origen': tablaOrigen,
      'registro_id_local': registroIdLocal,
      'operacion': operacion,
      'payload_json': payloadJson,
      'fecha_creacion': fechaCreacion,
      'intentos': intentos,
      'estado': estado,
      'error_mensaje': errorMensaje,
    };
  }
}
