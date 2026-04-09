import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/proyectos_controller.dart';
import '../middlewares/auth_middleware.dart';

Router buildProyectosRoutes() {
  final router = Router()
    ..get('/', listarProyectos)
    ..post('/', crearProyecto)
    ..get('/<proyecto_id>', obtenerProyecto)
    ..put('/<proyecto_id>', actualizarProyecto)
    ..delete('/<proyecto_id>', desactivarProyecto);

  return router;
}

Handler buildProyectosProtectedHandler() {
  return Pipeline()
      .addMiddleware(authMiddleware())
      .addHandler(buildProyectosRoutes());
}

Future<Response> obtenerProyecto(Request request, String proyectoId) {
  return obtenerProyectoPorId(request, proyectoId);
}
