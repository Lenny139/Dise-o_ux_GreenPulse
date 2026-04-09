class Usuario {
  final int usuarioId;
  final String nombre;
  final String correo;

  const Usuario({
    required this.usuarioId,
    required this.nombre,
    required this.correo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      usuarioId: _toInt(json['usuario_id']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'usuario_id': usuarioId, 'nombre': nombre, 'correo': correo};
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
