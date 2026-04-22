import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/proyecto.dart';
import '../backup/repositories/proyectos_repository.dart';

class ProyectosService {
  final Dio _dio = ApiClient.instance.dio;
  final _repo = ProyectosRepository.instance;

  Future<List<Proyecto>> getProyectos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt(USUARIO_ID_KEY);
      final params = <String, dynamic>{'solo_activos': true};
      if (usuarioId != null) params['usuario_id'] = usuarioId;

      final response = await _dio.get('/proyectos', queryParameters: params);
      final list = response.data;
      if (list is! List) return const [];

      final proyectos = list
          .whereType<Map>()
          .map((item) => Proyecto.fromJson(_asMap(item)))
          .toList();

      await _repo.guardarProyectos(proyectos);
      return proyectos;
    } on DioException {
      // Sin conexión → datos locales
      return _repo.obtenerProyectos();
    }
  }

  Future<Proyecto> getProyecto(int id) async {
    try {
      final response = await _dio.get('/proyectos/$id');
      final proyecto = Proyecto.fromJson(_asMap(response.data));
      await _repo.guardarProyectos([proyecto]);
      return proyecto;
    } on DioException {
      final local = await _repo.obtenerProyecto(id);
      if (local != null) return local;
      throw Exception('Proyecto no disponible sin conexión');
    }
  }

  Future<Proyecto> crearProyecto({
    required String nombre,
    required String tipo,
    String? coordenadas,
    String? descripcion,
    double? areaMetrosCuadrados,
  }) async {
    try {
      final data = <String, dynamic>{'nombre': nombre, 'tipo': tipo};
      if (coordenadas != null && coordenadas.isNotEmpty) {
        data['coordenadas'] = coordenadas;
        data['ubicacion_texto'] = coordenadas;
      }
      if (descripcion != null) data['descripcion'] = descripcion;
      if (areaMetrosCuadrados != null) {
        data['area_metros_cuadrados'] = areaMetrosCuadrados;
      }
      final response = await _dio.post('/proyectos', data: data);
      final proyecto = Proyecto.fromJson(_asMap(response.data));
      await _repo.guardarProyectos([proyecto]);
      return proyecto;
    } on DioException catch (e) {
      throw Exception(ApiClient.readableError(e));
    }
  }

  Future<Proyecto> actualizarProyecto(
    int id, {
    String? nombre,
    String? tipo,
    String? descripcion,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nombre != null) data['nombre'] = nombre;
      if (tipo != null) data['tipo'] = tipo;
      if (descripcion != null) data['descripcion'] = descripcion;
      final response = await _dio.put('/proyectos/$id', data: data);
      final proyecto = Proyecto.fromJson(_asMap(response.data));
      await _repo.guardarProyectos([proyecto]);
      return proyecto;
    } on DioException catch (e) {
      throw Exception(ApiClient.readableError(e));
    }
  }

  Future<void> eliminarProyecto(int id) async {
    try {
      await _dio.delete('/proyectos/$id');
      await _repo.eliminarProyecto(id);
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
