import 'dart:convert';

import 'package:shelf/shelf.dart';

Future<Response> getHealth(Request request) async {
  return Response.ok(
    jsonEncode({
      'success': true,
      'message': 'GreenPulse backend Dart operativo',
      'timestamp': DateTime.now().toIso8601String(),
    }),
    headers: {'content-type': 'application/json'},
  );
}
