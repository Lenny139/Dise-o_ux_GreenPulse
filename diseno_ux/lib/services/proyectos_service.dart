import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/lote.dart';

class ProyectosService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Lote>> getProyectos() async {
    try {
      final response = await _dio.get('/proyectos');
      final data = _asMap(response.data);
      final list = _extractList(data, preferredKey: 'proyectos');
      return list.map((item) => Lote.fromJson(_normalizeLote(item))).toList();
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<Lote> getProyecto(int id) async {
    try {
      final response = await _dio.get('/proyectos/$id');
      final data = _asMap(response.data);

      final payload = (data['proyecto'] is Map)
          ? _asMap(data['proyecto'])
          : (data['data'] is Map)
          ? _asMap(data['data'])
          : data;

      return Lote.fromJson(_normalizeLote(payload));
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<Lote> crearProyecto(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/proyectos', data: data);
      final responseMap = _asMap(response.data);
      return Lote.fromJson(_normalizeLote(responseMap));
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<void> eliminarProyecto(int id) async {
    try {
      await _dio.delete('/proyectos/$id');
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> data, {
    required String preferredKey,
  }) {
    final candidate = data[preferredKey] ?? data['data'] ?? data['items'];
    if (candidate is List) {
      return candidate
          .whereType<Map>()
          .map((item) => _asMap(item))
          .toList(growable: false);
    }

    if (data.values.length == 1 && data.values.first is List) {
      final list = data.values.first as List;
      return list
          .whereType<Map>()
          .map((item) => _asMap(item))
          .toList(growable: false);
    }

    return const [];
  }

  Map<String, dynamic> _normalizeLote(Map<String, dynamic> raw) {
    final output = Map<String, dynamic>.from(raw);

    final dynamic rawId =
        output['lote_id'] ?? output['proyecto_id'] ?? output['id'];
    if (rawId != null) {
      output['lote_id'] = _parseLoteId(rawId);
    }

    if (!output.containsKey('fecha_inicio_cultivo')) {
      output['fecha_inicio_cultivo'] = output['fecha_creacion'];
    }

    return output;
  }

  int _parseLoteId(dynamic value) {
    if (value is int) return value;
    final text = value.toString();
    final match = RegExp(r'lote_(\d+)', caseSensitive: false).firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return int.tryParse(text) ?? 0;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw Exception('Formato de respuesta inválido');
  }
}
