import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/alerta.dart';
import '../backup/repositories/alertas_repository.dart';

class AlertasService {
  final Dio _dio = ApiClient.instance.dio;
  final _repo = AlertasRepository.instance;

  Future<List<Alerta>> getAlertas() async {
    try {
      final response = await _dio.get('/alertas');
      final data = _asMap(response.data);

      final rows = (data['alertas'] is List)
          ? data['alertas'] as List
          : (data['data'] is List)
              ? data['data'] as List
              : const [];

      final alertas = rows
          .whereType<Map>()
          .map((json) => Alerta.fromJson(_asMap(json)))
          .toList(growable: false);

      await _repo.guardarAlertas(alertas);
      return alertas;
    } on DioException {
      return _repo.obtenerAlertas();
    }
  }

  Future<void> marcarLeida(int alertaId) async {
    try {
      await _dio.patch('/alertas/$alertaId/leida');
      await _repo.marcarLeida(alertaId);
    } on DioException catch (e) {
      throw Exception(ApiClient.readableError(e));
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
