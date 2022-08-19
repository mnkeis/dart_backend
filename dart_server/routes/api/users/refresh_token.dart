import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:user_repository/user_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.post:
      return _postHandler(context);
    case HttpMethod.put:
    case HttpMethod.delete:
    case HttpMethod.get:
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _postHandler(RequestContext context) async {
  try {
    final body = await context.request.json();
    final refreshToken = body['refreshToken'] as String?;
    if (refreshToken != null) {
      final userRepository = context.read<UserRepository>();
      final result =
          await userRepository.createAccessTokenFromRefreshToken(refreshToken);
      final tokens = result.asValue?.value;
      if (tokens != null) {
        return Response.json(body: tokens);
      }
      if (result.isError) {
        final error = result.asError!.error;
        if (error is TokenException) {
          String body;
          switch (error.failure) {
            case TokenFailure.tokenExpired:
              body = 'refresh-token-expired';
              break;
            case TokenFailure.refreshTokenReused:
            case TokenFailure.tokenInvalid:
              body = 'refresh-token-invalid';
              break;
          }
          return Response(statusCode: HttpStatus.unauthorized, body: body);
        }
      }
      return Response(statusCode: HttpStatus.internalServerError);
    } else {
      return Response(statusCode: HttpStatus.badRequest);
    }
  } on FormatException {
    return Response(statusCode: HttpStatus.badRequest);
  }
}
