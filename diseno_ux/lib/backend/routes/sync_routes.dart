import 'package:shelf_router/shelf_router.dart';

import '../controllers/sync_controller.dart';

Router buildSyncRoutes() {
  final router = Router()
    ..post('/push', pushSync)
    ..get('/pull', pullSync);

  return router;
}
