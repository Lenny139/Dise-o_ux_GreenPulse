import 'package:dio/dio.dart';
import '../core/api_client.dart';

// ─── Resumen (para listas y dropdown de cultivos) ─────────────────────────────

class PlantaSummary {
  final int id;
  final String nombreComun;
  final String? nombreCientifico;
  final String? categoria;
  final String? icono;

  const PlantaSummary({
    required this.id,
    required this.nombreComun,
    this.nombreCientifico,
    this.categoria,
    this.icono,
  });

  factory PlantaSummary.fromJson(Map<String, dynamic> json) {
    return PlantaSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombreComun: (json['nombre_comun'] ?? '').toString(),
      nombreCientifico: json['nombre_cientifico']?.toString(),
      categoria: json['categoria']?.toString(),
      icono: json['icono']?.toString(),
    );
  }
}

// ─── Detalle completo ─────────────────────────────────────────────────────────

class PlantaDetalle {
  final int id;
  final String nombreComun;
  final String? nombreCientifico;
  final String? categoria;
  final String? variedades;
  final double? temperaturaMin;
  final double? temperaturaMax;
  final double? humedadMin;
  final double? humedadMax;
  final double? phMin;
  final double? phMax;
  final int? cicloDiasMin;
  final int? cicloDiasMax;
  final bool esPerenne;
  final String? requerimientoAgua;
  final int? altitudMinMsnm;
  final int? altitudMaxMsnm;
  final String? regionTipica;
  final String? icono;
  final String? notas;

  const PlantaDetalle({
    required this.id,
    required this.nombreComun,
    this.nombreCientifico,
    this.categoria,
    this.variedades,
    this.temperaturaMin,
    this.temperaturaMax,
    this.humedadMin,
    this.humedadMax,
    this.phMin,
    this.phMax,
    this.cicloDiasMin,
    this.cicloDiasMax,
    this.esPerenne = false,
    this.requerimientoAgua,
    this.altitudMinMsnm,
    this.altitudMaxMsnm,
    this.regionTipica,
    this.icono,
    this.notas,
  });

  factory PlantaDetalle.fromJson(Map<String, dynamic> json) {
    return PlantaDetalle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombreComun: (json['nombre_comun'] ?? '').toString(),
      nombreCientifico: json['nombre_cientifico']?.toString(),
      categoria: json['categoria']?.toString(),
      variedades: json['variedades']?.toString(),
      temperaturaMin: _toDouble(json['temperatura_min']),
      temperaturaMax: _toDouble(json['temperatura_max']),
      humedadMin: _toDouble(json['humedad_min']),
      humedadMax: _toDouble(json['humedad_max']),
      phMin: _toDouble(json['ph_min']),
      phMax: _toDouble(json['ph_max']),
      cicloDiasMin: _toInt(json['ciclo_dias_min']),
      cicloDiasMax: _toInt(json['ciclo_dias_max']),
      esPerenne: json['es_perenne'] == true || json['es_perenne'] == 1,
      requerimientoAgua: json['requerimiento_agua']?.toString(),
      altitudMinMsnm: _toInt(json['altitud_min_msnm']),
      altitudMaxMsnm: _toInt(json['altitud_max_msnm']),
      regionTipica: json['region_tipica']?.toString(),
      icono: json['icono']?.toString(),
      notas: json['notas']?.toString(),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

// ─── Servicio ─────────────────────────────────────────────────────────────────

class PlantasService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<PlantaSummary>> getPlantas({String? categoria}) async {
    try {
      final params = <String, dynamic>{};
      if (categoria != null) params['categoria'] = categoria;

      final response = await _dio.get('/plantas', queryParameters: params);
      final list = response.data;
      if (list is! List) return const [];

      return list
          .whereType<Map>()
          .map((item) => PlantaSummary.fromJson(
                item.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .toList();
    } on DioException catch (e) {
      throw Exception(ApiClient.readableError(e));
    }
  }

  Future<PlantaDetalle> getPlanta(int id) async {
    try {
      final response = await _dio.get('/plantas/$id');
      final data = response.data;
      final map = data is Map<String, dynamic>
          ? data
          : (data as Map).map((k, v) => MapEntry(k.toString(), v));
      return PlantaDetalle.fromJson(map);
    } on DioException catch (e) {
      throw Exception(ApiClient.readableError(e));
    }
  }

  Future<List<String>> getCategorias() async {
    try {
      final response = await _dio.get('/plantas/categorias');
      final data = response.data;
      final list = data is Map ? data['categorias'] : data;
      if (list is! List) return const [];
      return list.map((e) => e.toString()).toList();
    } on DioException {
      return const [];
    }
  }
}
