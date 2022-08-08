import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:frog_jwt/frog_jwt.dart';

Handler middleware(Handler handler) {
  final secret = Platform.environment['SECRET'] ?? 'my-secret';
  return handler.use(provider<String>((context) => secret)).use(
        frogJwt(
          secret: secret,
          unless: [const UriPath('user/authenticate')],
          getToken: (request) {
            return request.headers['Authorization']
                    ?.replaceFirst('Bearer ', '') ??
                request.url.queryParameters['token'];
          },
          onError: (error) {
            if (error is JWTError) {
              return Response(
                statusCode: HttpStatus.unauthorized,
                body: error.message,
              );
            }
            return Response(
              statusCode: HttpStatus.badRequest,
              body: 'unknown-error',
            );
          },
        ),
      );
}
