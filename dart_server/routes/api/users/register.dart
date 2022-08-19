import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:user_repository/user_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getHandler(context);
    case HttpMethod.post:
      return _postHandler(context);
    case HttpMethod.put:
    case HttpMethod.delete:
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getHandler(RequestContext context) async {
  final userRepository = context.read<UserRepository>();
  final username = context.request.url.queryParameters['username'];
  if (username == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }
  final result = await userRepository.verifyUsername(username);
  if (result.asValue != null) {
    return Response.json(body: {'isAvailable': result.asValue!.value});
  }
  return Response(statusCode: HttpStatus.internalServerError);
}

Future<Response> _postHandler(RequestContext context) async {
  try {
    final body = await context.request.json();
    final user = User.fromJson({...body, 'id': -1});
    final password = body['password'] as String;
    final userRepository = context.read<UserRepository>();
    final result = await userRepository.addUser(user: user, password: password);
    if (result.asValue != null) {
      return Response.json(
        body: result.asValue!.value,
      );
    }
    if (result.isError) {
      final error = result.asError!.error;
      if (error is AuthenticationException) {
        if (error.failure == AuthenticationFailure.usernameNotAvailable) {
          return Response(
            statusCode: HttpStatus.badRequest,
            body: 'username-not-available',
          );
        }
      }
      return Response(statusCode: HttpStatus.internalServerError);
    } else {
      return Response(statusCode: HttpStatus.badRequest);
    }
  } catch (e) {
    print(e);
    return Response(statusCode: HttpStatus.badRequest);
  }
}
