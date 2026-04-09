import 'package:shelf_router/shelf_router.dart';

import '../controllers/cultivos_controller.dart';

Router buildCultivosRoutes() {
  final router = Router()
    ..get('/<cultivo_id>', obtenerCultivo)
    ..put('/<cultivo_id>', actualizarCultivo)
    ..delete('/<cultivo_id>', eliminarCultivo);

  return router;
}

Router buildCultivosNestedRoutes() {
  final router = Router()
    ..get('/<proyecto_id>/cultivos', listarCultivosPorProyecto)
    ..post('/<proyecto_id>/cultivos', crearCultivo);

  return router;
}
