import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/alerta.dart';

class AlertasService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Alerta>> getAlertas() async {
    try {
      final response = await _dio.get('/alertas');
      final data = _asMap(response.data);

      final rows = (data['alertas'] is List)
          ? (data['alertas'] as List)
          : (data['data'] is List)
          ? (data['data'] as List)
          : const [];

      return rows
          .whereType<Map>()
          .map((json) => Alerta.fromJson(_asMap(json)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<void> marcarLeida(int alertaId) async {
    try {
      await _dio.patch('/alertas/$alertaId/leida');
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
}
