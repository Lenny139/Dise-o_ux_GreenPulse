import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/constants.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'correo': correo, 'contrasena': contrasena},
      );

      final data = _asMap(response.data);
      final token = _extractToken(data);
      if (token == null || token.isEmpty) {
        throw Exception('La respuesta de login no contiene token');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TOKEN_KEY, token);

      // Guardar usuario_id para filtrar proyectos por usuario
      final usuarioId =
          _toInt(data['usuario_id']) ??
          _toInt((data['usuario'] as Map?)?['id']);
      if (usuarioId != null) {
        await prefs.setInt(USUARIO_ID_KEY, usuarioId);
      }

      final usuario = data['usuario'];
      if (usuario is Map) {
        final map = usuario.map((k, v) => MapEntry(k.toString(), v));
        final nombre = map['nombre']?.toString();
        final correoGuardado = map['correo']?.toString();
        if (nombre != null && nombre.isNotEmpty) {
          await prefs.setString('usuario_nombre', nombre);
        }
        if (correoGuardado != null && correoGuardado.isNotEmpty) {
          await prefs.setString('usuario_correo', correoGuardado);
        }
      }

      return data;
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<Map<String, dynamic>> registro(
    String nombre,
    String correo,
    String contrasena,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/registro',
        data: {'nombre': nombre, 'correo': correo, 'contrasena': contrasena},
      );
      return _asMap(response.data);
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
    await prefs.remove(USUARIO_ID_KEY);
    await prefs.remove('usuario_nombre');
    await prefs.remove('usuario_correo');
  }

  Future<Map<String, dynamic>> getPerfil() async {
    try {
      final response = await _dio.get('/auth/perfil');
      final data = _asMap(response.data);
      final usuario = data['usuario'];
      if (usuario is Map) {
        final map = usuario.map((k, v) => MapEntry(k.toString(), v));
        await _persistUserPrefs(map);
      }
      return data;
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<Map<String, dynamic>> actualizarPerfil({
    required String nombre,
    required String correo,
  }) async {
    try {
      final response = await _dio.put(
        '/auth/perfil',
        data: {'nombre': nombre, 'correo': correo},
      );
      final data = _asMap(response.data);
      final usuario = data['usuario'];
      if (usuario is Map) {
        final map = usuario.map((k, v) => MapEntry(k.toString(), v));
        await _persistUserPrefs(map);
      }
      return data;
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<void> cambiarContrasena({
    required String actualContrasena,
    required String nuevaContrasena,
  }) async {
    try {
      await _dio.patch(
        '/auth/contrasena',
        data: {
          'actual_contrasena': actualContrasena,
          'nueva_contrasena': nuevaContrasena,
        },
      );
    } on DioException catch (error) {
      throw Exception(ApiClient.readableError(error));
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(TOKEN_KEY);
    return token != null && token.isNotEmpty;
  }

  String? _extractToken(Map<String, dynamic> data) {
    final rootToken = data['token'] ?? data['access_token'] ?? data['jwt'];
    if (rootToken != null) return rootToken.toString();
    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      final t = nested['token'] ?? nested['access_token'] ?? nested['jwt'];
      if (t != null) return t.toString();
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw Exception('Formato de respuesta inválido');
  }

  Future<void> _persistUserPrefs(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = userMap['nombre']?.toString();
    final correo = userMap['correo']?.toString();
    if (nombre != null && nombre.isNotEmpty) {
      await prefs.setString('usuario_nombre', nombre);
    }
    if (correo != null && correo.isNotEmpty) {
      await prefs.setString('usuario_correo', correo);
    }
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
