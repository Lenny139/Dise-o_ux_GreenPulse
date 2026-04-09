import 'dart:convert';

import 'package:shelf/shelf.dart';

Middleware errorHandlerMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (error) {
        return Response.internalServerError(
          body: jsonEncode({
            'error': 'Error interno del servidor',
            'detalle': error.toString(),
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
