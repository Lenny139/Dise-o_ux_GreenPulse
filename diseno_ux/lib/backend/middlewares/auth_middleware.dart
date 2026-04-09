import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../config/env.dart';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(
          401,
          body: jsonEncode({'error': 'Token no proporcionado'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final token = authHeader.substring(7).trim();

      try {
        final jwt = JWT.verify(token, SecretKey(envOrThrow('JWT_SECRET')));
        final payload = Map<String, dynamic>.from(jwt.payload as Map);
        final requestWithContext = request.change(
          context: {
            ...request.context,
            'usuario': {
              'usuario_id': payload['usuario_id'],
              'correo': payload['correo'],
              'nombre': payload['nombre'],
            },
          },
        );
        return innerHandler(requestWithContext);
      } catch (_) {
        return Response(
          401,
          body: jsonEncode({'error': 'Token inválido o expirado'}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
