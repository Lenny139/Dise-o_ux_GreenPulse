import 'model_utils.dart';

class RegistroAgronomico {
  static const String tableName = 'REGISTRO_AGRONOMICO';

  final int? registroId;
  final int loteId;
  final int usuarioId;
  final double? temperatura;
  final double? humedad;
  final double? ph;
  final String? observaciones;
  final String metodoCaptura;
  final DateTime fechaHoraRegistro;
  final DateTime fechaHoraGuardado;
  final String syncEstado;
  final String? syncIdRemoto;

  const RegistroAgronomico({
    this.registroId,
    required this.loteId,
    required this.usuarioId,
    this.temperatura,
    this.humedad,
    this.ph,
    this.observaciones,
    this.metodoCaptura = 'MANUAL',
    required this.fechaHoraRegistro,
    required this.fechaHoraGuardado,
    required this.syncEstado,
    this.syncIdRemoto,
  });

  factory RegistroAgronomico.fromMap(Map<String, dynamic> map) {
    return RegistroAgronomico(
      registroId: map['registro_id'] as int?,
      loteId: map['lote_id'] as int,
      usuarioId: map['usuario_id'] as int,
      temperatura: (map['temperatura'] as num?)?.toDouble(),
      humedad: (map['humedad'] as num?)?.toDouble(),
      ph: (map['ph'] as num?)?.toDouble(),
      observaciones: map['observaciones'] as String?,
      metodoCaptura: (map['metodo_captura'] as String?) ?? 'MANUAL',
      fechaHoraRegistro: parseDateTime(map['fecha_hora_registro'])!,
      fechaHoraGuardado: parseDateTime(map['fecha_hora_guardado'])!,
      syncEstado: map['sync_estado'] as String,
      syncIdRemoto: map['sync_id_remoto'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'registro_id': registroId,
      'lote_id': loteId,
      'usuario_id': usuarioId,
      'temperatura': temperatura,
      'humedad': humedad,
      'ph': ph,
      'observaciones': observaciones,
      'metodo_captura': metodoCaptura,
      'fecha_hora_registro': fechaHoraRegistro,
      'fecha_hora_guardado': fechaHoraGuardado,
      'sync_estado': syncEstado,
      'sync_id_remoto': syncIdRemoto,
    };
  }

  bool get temperaturaValida =>
      temperatura == null || (temperatura! >= -10 && temperatura! <= 60);
  bool get humedadValida =>
      humedad == null || (humedad! >= 0 && humedad! <= 100);
  bool get phValido => ph == null || (ph! >= 0 && ph! <= 14);
}
