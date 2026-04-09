import 'package:dio/dio.dart';

import '../core/api_client.dart';

class EstadisticasService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getEstadisticas(int cultivoId) async {
    try {
      final response = await _dio.get('/cultivos/$cultivoId/estadisticas');
      return _asMap(response.data);
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
