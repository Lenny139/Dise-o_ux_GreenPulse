import 'package:shelf_router/shelf_router.dart';

import '../controllers/alertas_controller.dart';

Router buildAlertasRoutes() {
  final router = Router()
    ..get('/', listarAlertasNoLeidas)
    ..patch('/<alerta_id>/leida', marcarAlertaLeida);

  return router;
}
