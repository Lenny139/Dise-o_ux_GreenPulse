import 'app.dart';
import 'config/database.dart';
import 'config/env.dart';

Future<void> startBackend() async {
  loadBackendEnv();

  final connected = await initializeDatabase();
  if (!connected) {
    return;
  }

  final port = int.tryParse(backendEnv['PORT'] ?? '3000') ?? 3000;
  await runServer(port: port);
}
