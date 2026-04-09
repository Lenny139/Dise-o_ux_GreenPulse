export 'alerta_generada.dart';
export 'configuracion_alerta.dart';
export 'evento_operativo.dart';
export 'exportacion_historial.dart';
export 'finca.dart';
export 'lote.dart';
export 'registro_agronomico.dart';
export 'sync_queue.dart';
export 'tipo_labor.dart';
export 'usuario.dart';

class ModelRelation {
  final String type;
  final String source;
  final String target;
  final String foreignKey;

  const ModelRelation({
    required this.type,
    required this.source,
    required this.target,
    required this.foreignKey,
  });
}

const List<ModelRelation> modelRelations = [
  ModelRelation(
    type: 'hasMany',
    source: 'USUARIO',
    target: 'FINCA',
    foreignKey: 'usuario_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'FINCA',
    target: 'USUARIO',
    foreignKey: 'usuario_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'FINCA',
    target: 'LOTE',
    foreignKey: 'finca_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'LOTE',
    target: 'FINCA',
    foreignKey: 'finca_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'LOTE',
    target: 'REGISTRO_AGRONOMICO',
    foreignKey: 'lote_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'REGISTRO_AGRONOMICO',
    target: 'LOTE',
    foreignKey: 'lote_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'USUARIO',
    target: 'REGISTRO_AGRONOMICO',
    foreignKey: 'usuario_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'REGISTRO_AGRONOMICO',
    target: 'USUARIO',
    foreignKey: 'usuario_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'TIPO_LABOR',
    target: 'EVENTO_OPERATIVO',
    foreignKey: 'tipo_labor_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'EVENTO_OPERATIVO',
    target: 'TIPO_LABOR',
    foreignKey: 'tipo_labor_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'LOTE',
    target: 'EVENTO_OPERATIVO',
    foreignKey: 'lote_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'EVENTO_OPERATIVO',
    target: 'LOTE',
    foreignKey: 'lote_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'USUARIO',
    target: 'EVENTO_OPERATIVO',
    foreignKey: 'usuario_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'EVENTO_OPERATIVO',
    target: 'USUARIO',
    foreignKey: 'usuario_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'LOTE',
    target: 'CONFIGURACION_ALERTA',
    foreignKey: 'lote_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'CONFIGURACION_ALERTA',
    target: 'LOTE',
    foreignKey: 'lote_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'USUARIO',
    target: 'CONFIGURACION_ALERTA',
    foreignKey: 'usuario_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'CONFIGURACION_ALERTA',
    target: 'USUARIO',
    foreignKey: 'usuario_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'REGISTRO_AGRONOMICO',
    target: 'ALERTA_GENERADA',
    foreignKey: 'registro_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'ALERTA_GENERADA',
    target: 'REGISTRO_AGRONOMICO',
    foreignKey: 'registro_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'CONFIGURACION_ALERTA',
    target: 'ALERTA_GENERADA',
    foreignKey: 'config_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'ALERTA_GENERADA',
    target: 'CONFIGURACION_ALERTA',
    foreignKey: 'config_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'USUARIO',
    target: 'EXPORTACION_HISTORIAL',
    foreignKey: 'usuario_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'EXPORTACION_HISTORIAL',
    target: 'USUARIO',
    foreignKey: 'usuario_id',
  ),

  ModelRelation(
    type: 'hasMany',
    source: 'LOTE',
    target: 'EXPORTACION_HISTORIAL',
    foreignKey: 'lote_id',
  ),
  ModelRelation(
    type: 'belongsTo',
    source: 'EXPORTACION_HISTORIAL',
    target: 'LOTE',
    foreignKey: 'lote_id',
  ),
];
