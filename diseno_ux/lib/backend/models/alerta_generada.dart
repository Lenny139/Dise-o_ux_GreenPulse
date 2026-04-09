import 'model_utils.dart';

class AlertaGenerada {
  static const String tableName = 'ALERTA_GENERADA';

  final int? alertaId;
  final int registroId;
  final int configId;
  final String mensaje;
  final DateTime fechaHora;
  final int leida;

  const AlertaGenerada({
    this.alertaId,
    required this.registroId,
    required this.configId,
    required this.mensaje,
    required this.fechaHora,
    this.leida = 0,
  });

  factory AlertaGenerada.fromMap(Map<String, dynamic> map) {
    return AlertaGenerada(
      alertaId: map['alerta_id'] as int?,
      registroId: map['registro_id'] as int,
      configId: map['config_id'] as int,
      mensaje: map['mensaje'] as String,
      fechaHora: parseDateTime(map['fecha_hora'])!,
      leida: (map['leida'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alerta_id': alertaId,
      'registro_id': registroId,
      'config_id': configId,
      'mensaje': mensaje,
      'fecha_hora': fechaHora,
      'leida': leida,
    };
  }
}
