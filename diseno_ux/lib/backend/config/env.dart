import 'package:dotenv/dotenv.dart';

final DotEnv backendEnv = DotEnv(includePlatformEnvironment: true);

void loadBackendEnv() {
  backendEnv.load(['lib/backend/.env']);
}

String envOrThrow(String key) {
  final value = backendEnv[key];
  if (value == null || value.isEmpty) {
    throw StateError('Falta variable de entorno requerida: $key');
  }
  return value;
}
