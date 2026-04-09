import 'package:shelf_router/shelf_router.dart';

import '../controllers/estadisticas_controller.dart';

Router buildEstadisticasRoutes() {
  final router = Router()
    ..get('/<cultivo_id>/estadisticas', obtenerEstadisticas);

  return router;
}

Router buildEstadisticasNestedRoutes() {
  final router = Router()
    ..get('/<proyecto_id>/reporte-mensual', obtenerReporteMensual);

  return router;
}
