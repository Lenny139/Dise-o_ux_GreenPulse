class TipoLabor {
  static const String tableName = 'TIPO_LABOR';

  final int? tipoLaborId;
  final String nombre;
  final String? icono;
  final String? descripcion;

  const TipoLabor({
    this.tipoLaborId,
    required this.nombre,
    this.icono,
    this.descripcion,
  });

  factory TipoLabor.fromMap(Map<String, dynamic> map) {
    return TipoLabor(
      tipoLaborId: map['tipo_labor_id'] as int?,
      nombre: map['nombre'] as String,
      icono: map['icono'] as String?,
      descripcion: map['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo_labor_id': tipoLaborId,
      'nombre': nombre,
      'icono': icono,
      'descripcion': descripcion,
    };
  }
}
