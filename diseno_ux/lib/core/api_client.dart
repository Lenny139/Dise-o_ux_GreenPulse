import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: BASE_URL,
        connectTimeout: const Duration(seconds: TIMEOUT_SECONDS),
        receiveTimeout: const Duration(seconds: TIMEOUT_SECONDS),
        sendTimeout: const Duration(seconds: TIMEOUT_SECONDS),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(TOKEN_KEY);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(TOKEN_KEY);

            if (_onUnauthorized != null) {
              await _onUnauthorized!.call();
            } else {
              final navigator = navigatorKey?.currentState;
              if (navigator != null) {
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              }
            }
          }

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: readableError(error),
              stackTrace: error.stackTrace,
            ),
          );
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  static GlobalKey<NavigatorState>? navigatorKey;
  static Future<void> Function()? _onUnauthorized;

  static void setUnauthorizedHandler(Future<void> Function() handler) {
    _onUnauthorized = handler;
  }

  static String readableError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Tiempo de espera agotado. Verifica tu conexión.';
        case DioExceptionType.connectionError:
          return 'No se pudo conectar al servidor. Revisa internet o la URL del backend.';
        case DioExceptionType.badResponse:
          final responseData = error.response?.data;
          if (responseData is Map<String, dynamic>) {
            final apiMessage =
                responseData['error'] ??
                responseData['message'] ??
                responseData['detalle'];
            if (apiMessage != null) {
              return apiMessage.toString();
            }
          }
          return 'Error del servidor (${error.response?.statusCode ?? 500}).';
        case DioExceptionType.cancel:
          return 'La solicitud fue cancelada.';
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return 'Sin conexión a internet.';
          }
          return 'Ocurrió un error inesperado de red.';
        case DioExceptionType.badCertificate:
          return 'Certificado SSL inválido.';
      }
    }

    return 'Error inesperado';
  }
}
