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

      final usuario = data['usuario'];
      if (usuario is Map) {
        final map = usuario.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final nombre = map['nombre']?.toString();
        final correo = map['correo']?.toString();
        if (nombre != null && nombre.isNotEmpty) {
          await prefs.setString('usuario_nombre', nombre);
        }
        if (correo != null && correo.isNotEmpty) {
          await prefs.setString('usuario_correo', correo);
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
      final nestedToken =
          nested['token'] ?? nested['access_token'] ?? nested['jwt'];
      if (nestedToken != null) return nestedToken.toString();
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw Exception('Formato de respuesta inválido');
  }
}
