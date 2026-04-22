import 'package:flutter/foundation.dart';

const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';
const String _localBaseUrl = 'http://127.0.0.1:8000/api/v1';
const String _physicalDeviceUrl =
    'http://192.168.1.12:8000/api/v1'; // ← tu IP real

final String BASE_URL = kIsWeb
    ? _localBaseUrl
    : _physicalDeviceUrl; // ← usa esta para dispositivo físico

const int TIMEOUT_SECONDS = 30;
const String TOKEN_KEY = 'token';
const String USUARIO_ID_KEY = 'usuario_id';
