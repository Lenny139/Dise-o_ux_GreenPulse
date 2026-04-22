import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/cultivo.dart';
import '../models/registro_agronomico.dart';
import '../backup/repositories/cultivos_repository.dart';
import '../backup/repositories/registros_repository.dart';

class CultivosService {
  final Dio _dio = ApiClient.instance.dio;
  final _cultivosRepo = CultivosRepository.instance;
  final _registrosRepo = RegistrosRepository.instance;
  int lastAlertasGeneradas = 0;

  // ─── Cultivos ─────────────────────────────────────────────────────────────

  Future<List<Cultivo>> getCultivos(int proyectoId) async {
    try {
      final response = await _dio.get('/proyectos/$proyectoId/cultivos');
      final list = response.data;
      if (list is! List) return const [];

      final cultivos = list
          .whereType<Map>()
          .map((item) => Cultivo.fromJson(_asMap(item)))
          .toList();

      await _cultivosRepo.guardarCultivos(proyectoId, cultivos);
      return cultivos;
    } on DioException {
      return _cultivosRepo.obtenerCultivos(proyectoId);
    }
  }

  Future<Cultivo> crearCultivo(
    int proyectoId, {
    required int plantaId,
    required String nombreLote,
    double? areaM2,
    int? cantidadPlantas,
    String? variedad,
  }) async {
    try {
      final data = <String, dynamic>{
        'planta_id': plantaId,
        'nombre_lote': nombreLote,
      };
      if (areaM2 != null) data['area_m2'] = areaM2;
      if (cantidadPlantas != null) data['cantidad_plantas'] = cantidadPlantas;
      if (variedad != null && variedad.isNotEmpty) data['variedad'] = variedad;

      final response = await _dio.post(
        '/proyectos/$proyectoId/cultivos',
        data: data,
      );
      final cultivo = Cultivo.fromJson(_asMap(response.data));

      // Refrescar cultivos del proyecto en local
      final todos = await getCultivos(proyectoId);
      await _cultivosRepo.guardarCultivos(proyectoId, todos);

      return cultivo;
    } on DioException catch (e) {
      throw Exception(ApiClient.readableError(e));
    }
  }

  Future<void> eliminarCultivo(int cultivoId) async {
    try {
      await _dio.delete('/cultivos/$cultivoId');
      await _cultivosRepo.eliminarCultivo(cultivoId);
    } on DioException catch (e) {
      throw Exception(ApiClient.readableError(e));
    }
  }

  // ─── Registros ────────────────────────────────────────────────────────────

  Future<List<RegistroAgronomico>> getRegistros(
    int cultivoId, {
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/cultivos/$cultivoId/registros',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final list = response.data;
      if (list is! List) return const [];

      final registros = list
          .whereType<Map>()
          .map((item) => RegistroAgronomico.fromJson(_asMap(item)))
          .toList();

      await _registrosRepo.guardarRegistros(cultivoId, registros);
      return registros;
    } on DioException {
      return _registrosRepo.obtenerRegistros(cultivoId);
    }
  }

  Future<RegistroAgronomico> crearRegistro(
    int cultivoId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/cultivos/$cultivoId/registros',
        data: data,
      );
      final body = _asMap(response.data);
      lastAlertasGeneradas = (body['alertas_generadas'] as num?)?.toInt() ?? 0;

      final registroRaw =
          body['registro'] is Map ? _asMap(body['registro']) : body;
      final registro = RegistroAgronomico.fromJson(registroRaw);

      // Guardar en local
      await _registrosRepo.guardarRegistro(cultivoId, registro);
      return registro;
    } on DioException catch (e) {
      throw Exception(ApiClient.readableError(e));
    }
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    throw Exception('Formato de respuesta inválido');
  }
}
