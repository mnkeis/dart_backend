import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:user_repository/user_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getHandler(context, id);
    case HttpMethod.put:
      return _putHandler(context, id);
    case HttpMethod.patch:
      return _patchHandler(context, id);
    case HttpMethod.delete:
      return _deleteHandler(context, id);
    case HttpMethod.head:
    case HttpMethod.post:
    case HttpMethod.options:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getHandler(RequestContext context, String id) async {
  final userId = int.tryParse(id);
  if (userId == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }
  final userRepository = context.read<UserRepository>();
  final result = await userRepository.getUser(userId);
  if (result.asValue != null) {
    final user = result.asValue!.value;
    final body = user.toJson()
      ..removeWhere((key, value) => key == 'refreshTokens');
    return Response.json(body: body);
  }
  return Response(statusCode: HttpStatus.badRequest);
}

Future<Response> _putHandler(RequestContext context, String id) async {
  try {
    final userRepository = context.read<UserRepository>();
    final body = await context.request.json();
    final username = body['username'] as String?;
    final password = body['password'] as String?;
    final newPassword = body['newPassword'] as String?;
    if (username != null && password != null && newPassword != null) {
      final result = await userRepository.updatePassword(
        username: username,
        password: password,
        newPassword: newPassword,
      );
      if (result.isError) {
        return Response(statusCode: HttpStatus.internalServerError);
      }
      return Response();
    }
    final user = User.fromJson(body);
    final result = await userRepository.updateProfile(user);
    if (result.isError) {
      return Response(statusCode: HttpStatus.internalServerError);
    }
    return Response();
  } catch (e) {
    return Response(statusCode: HttpStatus.badRequest);
  }
}

Future<Response> _patchHandler(RequestContext context, String id) async {
  try {
    final userRepository = context.read<UserRepository>();
    final body = await context.request.json();
    final newPassword = body['newPassword'] as String?;
    final userId = int.tryParse(id);
    if (userId != null && newPassword != null) {
      final result = await userRepository.recoverPassword(
        id: userId,
        newPassword: newPassword,
      );
      if (result.isError) {
        return Response(statusCode: HttpStatus.internalServerError);
      }
      return Response();
    }
    return Response(statusCode: HttpStatus.badRequest);
  } catch (e) {
    return Response(statusCode: HttpStatus.badRequest);
  }
}

Future<Response> _deleteHandler(RequestContext context, String id) async {
  try {
    final userRepository = context.read<UserRepository>();
    await userRepository.revokeAllRefreshTokens(int.parse(id));
    return Response();
  } on FormatException {
    return Response(statusCode: HttpStatus.badRequest);
  }
}
