import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middlewares/auth_middleware.dart';
import 'alertas_routes.dart';
import 'auth_routes.dart';
import 'cultivos_routes.dart';
import 'estadisticas_routes.dart';
import 'eventos_routes.dart';
import 'proyectos_routes.dart';
import 'sync_routes.dart';

Handler buildRouter() {
  Handler protected(Handler handler) =>
      Pipeline().addMiddleware(authMiddleware()).addHandler(handler);

  final router = Router()
    ..mount('/api/v1/auth', buildAuthRoutes())
    ..mount('/api/v1/proyectos', buildProyectosProtectedHandler())
    ..mount('/api/v1/proyectos', protected(buildCultivosNestedRoutes()))
    ..mount('/api/v1/proyectos', protected(buildEstadisticasNestedRoutes()))
    ..mount('/api/v1/cultivos', protected(buildCultivosRoutes()))
    ..mount('/api/v1/cultivos', protected(buildEstadisticasRoutes()))
    ..mount('/api/v1/alertas', protected(buildAlertasRoutes()))
    ..mount('/api/v1/eventos', protected(buildEventosRoutes()))
    ..mount('/api/v1/sync', protected(buildSyncRoutes()))
    ..get('/api/v1/health', (Request request) async {
      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'app': 'GreenPulse API',
          'version': '1.0.0',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
        headers: {'content-type': 'application/json'},
      );
    })
    ..all('/<ignored|.*>', (Request request) {
      return Response.notFound(
        jsonEncode({
          'error': 'Endpoint no encontrado',
          'path': '/${request.url.path}',
        }),
        headers: {'content-type': 'application/json'},
      );
    });

  return router;
}
