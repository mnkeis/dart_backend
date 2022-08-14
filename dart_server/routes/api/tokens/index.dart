import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:user_repository/user_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json();
      final username = body['username'] as String?;
      final password = body['password'] as String?;
      if (username != null && password != null) {
        final userRepository = context.read<UserRepository>();
        final result =
            await userRepository.createAccessTokenFromUsernameAndPassword(
          username: username,
          password: password,
        );
        if (result.isError) {
          final error = result.asError!.error;
          if (error is AuthenticationException &&
              error.failure ==
                  AuthenticationFailure.invalidUsernameOrPassword) {
            return Response(
              statusCode: HttpStatus.unauthorized,
              body: 'invalid-username-or-password',
              headers: <String, String>{
                'WWW-Authenticate': 'Basic',
              },
            );
          }
          return Response(statusCode: HttpStatus.internalServerError);
        }
        if (result.asValue != null) {
          return Response.json(
            body: result.asValue!.value,
          );
        }
      } else {
        return Response(statusCode: HttpStatus.badRequest);
      }
    } on FormatException {
      return Response(statusCode: HttpStatus.badRequest);
    }
  } else if (context.request.method == HttpMethod.put) {
    try {
      final body = await context.request.json();
      final refreshToken = body['refreshToken'] as String?;
      if (refreshToken != null) {
        final userRepository = context.read<UserRepository>();
        final result = await userRepository
            .createAccessTokenFromRefreshToken(refreshToken);
        final tokens = result.asValue?.value;
        if (tokens != null) {
          return Response.json(body: tokens);
        }
        if (result.isError) {
          final error = result.asError!.error;
          if (error is AuthenticationException) {
            String body;
            switch (error.failure) {
              case AuthenticationFailure.invalidUsernameOrPassword:
              case AuthenticationFailure.tokenExpired:
                body = 'refresh-token-expired';
                break;
              case AuthenticationFailure.refreshTokenReused:
              case AuthenticationFailure.tokenInvalid:
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
  return Response(statusCode: HttpStatus.methodNotAllowed);
}
