class ConfiguracionAlerta {
  static const String tableName = 'CONFIGURACION_ALERTA';

  final int? configId;
  final int loteId;
  final int usuarioId;
  final String variable;
  final double? umbralMinimo;
  final double? umbralMaximo;
  final int activa;
  final String syncEstado;

  const ConfiguracionAlerta({
    this.configId,
    required this.loteId,
    required this.usuarioId,
    required this.variable,
    this.umbralMinimo,
    this.umbralMaximo,
    this.activa = 1,
    required this.syncEstado,
  });

  factory ConfiguracionAlerta.fromMap(Map<String, dynamic> map) {
    return ConfiguracionAlerta(
      configId: map['config_id'] as int?,
      loteId: map['lote_id'] as int,
      usuarioId: map['usuario_id'] as int,
      variable: map['variable'] as String,
      umbralMinimo: (map['umbral_minimo'] as num?)?.toDouble(),
      umbralMaximo: (map['umbral_maximo'] as num?)?.toDouble(),
      activa: (map['activa'] as int?) ?? 1,
      syncEstado: map['sync_estado'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'config_id': configId,
      'lote_id': loteId,
      'usuario_id': usuarioId,
      'variable': variable,
      'umbral_minimo': umbralMinimo,
      'umbral_maximo': umbralMaximo,
      'activa': activa,
      'sync_estado': syncEstado,
    };
  }
}
