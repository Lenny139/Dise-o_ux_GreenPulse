import 'package:shelf_router/shelf_router.dart';

import '../controllers/eventos_controller.dart';

Router buildEventosRoutes() {
  final router = Router()
    ..get('/', listarEventosPendientes)
    ..post('/', crearEvento)
    ..patch('/<evento_id>/completar', completarEvento);

  return router;
}
