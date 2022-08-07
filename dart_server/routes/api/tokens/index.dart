import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  if (context.request.method == HttpMethod.post) {
    return Response(body: 'login');
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}
