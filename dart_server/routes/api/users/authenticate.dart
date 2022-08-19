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
      return _getHandler(context);
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getHandler(RequestContext context) async {
  final parameters = context.request.uri.queryParameters;
  final usernameOrEmail = parameters['username'] ?? parameters['email'];
  if (usernameOrEmail == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }
  final userRepository = context.read<UserRepository>();
  final result = await userRepository.getPasswordRecoveryToken(usernameOrEmail);
  if (result.isError) {
    final error = result.asError!.error;
    if (error is AuthenticationException) {
      final failure = error.failure;
      switch (failure) {
        case AuthenticationFailure.userNotFound:
          return Response(statusCode: HttpStatus.notFound);
        case AuthenticationFailure.invalidUsernameOrPassword:
        case AuthenticationFailure.usernameNotAvailable:
        case AuthenticationFailure.registrationFailed:
          break;
      }
    }
    return Response(statusCode: HttpStatus.internalServerError);
  }
  final token = result.asValue!.value;
  // TODO: send email to the user with password recovery link

  return Response();
}

Future<Response> _postHandler(RequestContext context) async {
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
      if (result.asValue != null) {
        return Response.json(
          body: result.asValue!.value,
        );
      }
      if (result.isError) {
        final error = result.asError!.error;
        if (error is AuthenticationException &&
            error.failure == AuthenticationFailure.invalidUsernameOrPassword) {
          return Response(
            statusCode: HttpStatus.unauthorized,
            body: 'invalid-username-or-password',
            headers: <String, String>{
              'WWW-Authenticate': 'Basic',
            },
          );
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
