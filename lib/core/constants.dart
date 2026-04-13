import 'package:flutter/foundation.dart';

const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';
const String _physicalDeviceBaseUrl = 'http://192.168.1.2:8000/api/v1';
const String _localBaseUrl = 'http://127.0.0.1:8000/api/v1';

final String BASE_URL = defaultTargetPlatform == TargetPlatform.android
    ? _physicalDeviceBaseUrl
    : _localBaseUrl;
const TIMEOUT_SECONDS = 30;
const TOKEN_KEY = 'token';
