import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'middlewares/error_handler.dart';
import 'routes/router.dart';

Handler buildApp() {
  return Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(errorHandlerMiddleware())
      .addHandler(buildRouter());
}

Future<void> runServer({required int port}) async {
  final server = await shelf_io.serve(buildApp(), '0.0.0.0', port);
  print('🚀 GreenPulse Dart backend escuchando en puerto ${server.port}');
}
