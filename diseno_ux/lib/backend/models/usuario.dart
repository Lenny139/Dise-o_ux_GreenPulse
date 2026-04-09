import 'model_utils.dart';

class Usuario {
  static const String tableName = 'USUARIO';

  final int? usuarioId;
  final String nombre;
  final String correo;
  final String contrasenaHash;
  final String? tokenFcm;
  final DateTime fechaRegistro;
  final int activo;
  final String syncEstado;

  const Usuario({
    this.usuarioId,
    required this.nombre,
    required this.correo,
    required this.contrasenaHash,
    this.tokenFcm,
    required this.fechaRegistro,
    required this.activo,
    required this.syncEstado,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      usuarioId: map['usuario_id'] as int?,
      nombre: map['nombre'] as String,
      correo: map['correo'] as String,
      contrasenaHash: map['contrasena_hash'] as String,
      tokenFcm: map['token_fcm'] as String?,
      fechaRegistro: parseDateTime(map['fecha_registro'])!,
      activo: map['activo'] as int,
      syncEstado: map['sync_estado'] as String,
    );
  }

  Map<String, dynamic> toMap({bool includePassword = true}) {
    final data = <String, dynamic>{
      'usuario_id': usuarioId,
      'nombre': nombre,
      'correo': correo,
      'token_fcm': tokenFcm,
      'fecha_registro': fechaRegistro,
      'activo': activo,
      'sync_estado': syncEstado,
    };

    if (includePassword) {
      data['contrasena_hash'] = contrasenaHash;
    }

    return data;
  }

  Map<String, dynamic> toPublicMap() => toMap(includePassword: false);
}
