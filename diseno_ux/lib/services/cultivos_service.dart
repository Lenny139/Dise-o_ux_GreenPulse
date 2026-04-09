import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/registro_agronomico.dart';

class CultivosService {
  final Dio _dio = ApiClient.instance.dio;
  int lastAlertasGeneradas = 0;

  Future<List<RegistroAgronomico>> getRegistros(
    int loteId, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/proyectos/$loteId/cultivos',
        queryParameters: {'page': page},
      );

      final data = _asMap(response.data);
      final rows = (data['registros'] is List)
          ? (data['registros'] as List)
          : (data['data'] is List)
          ? (data['data'] as List)
          : const [];

      return rows
          .whereType<Map>()
          .map((json) => RegistroAgronomico.fromJson(_asMap(json)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<RegistroAgronomico> crearRegistro(
    int loteId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/proyectos/$loteId/cultivos',
        data: data,
      );
      final body = _asMap(response.data);
      lastAlertasGeneradas = _toInt(body['alertas_generadas']) ?? 0;

      final payload = (body['registro'] is Map)
          ? _asMap(body['registro'])
          : (body['data'] is Map)
          ? _asMap(body['data'])
          : body;

      return RegistroAgronomico.fromJson(payload);
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw Exception('Formato de respuesta inválido');
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
