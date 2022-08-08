import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:user_repository/user_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    try {
      final body = await context.request.json();
      final username = body['username'] as String;
      final password = body['password'] as String;
      final userRepository = context.read<UserRepository>();
      final user = await userRepository.getUserWithUsernameAndPassword(
        username: username,
        password: password,
      );
      final secret = context.read<String>();
      print(user);
      print(secret);
      final jwt = JWT(user);
      final token = jwt.sign(
        SecretKey(secret),
        expiresIn: Duration(
          hours: int.parse(Platform.environment['TOKEN_EXPIRE'] ?? '4'),
        ),
      );
      return Response.json(
        body: {'token': token},
      );
    } on FormatException {
      return Response(statusCode: HttpStatus.badRequest);
    }
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}
