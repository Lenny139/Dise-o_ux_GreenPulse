class RegistroAgronomico {
  final int registroId;
  final double? temperatura;
  final double? humedad;
  final double? ph;
  final String? metodoCaptura;
  final DateTime? fechaHoraRegistro;
  final String? observaciones;

  const RegistroAgronomico({
    required this.registroId,
    this.temperatura,
    this.humedad,
    this.ph,
    this.metodoCaptura,
    this.fechaHoraRegistro,
    this.observaciones,
  });

  factory RegistroAgronomico.fromJson(Map<String, dynamic> json) {
    return RegistroAgronomico(
      registroId: _toInt(json['registro_id']) ?? 0,
      temperatura: _toDouble(json['temperatura']),
      humedad: _toDouble(json['humedad']),
      ph: _toDouble(json['ph']),
      metodoCaptura: json['metodo_captura']?.toString(),
      fechaHoraRegistro: _toDateTime(json['fecha_hora_registro']),
      observaciones: json['observaciones']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registro_id': registroId,
      'temperatura': temperatura,
      'humedad': humedad,
      'ph': ph,
      'metodo_captura': metodoCaptura,
      'fecha_hora_registro': fechaHoraRegistro?.toIso8601String(),
      'observaciones': observaciones,
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
