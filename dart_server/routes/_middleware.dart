import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:frog_jwt/frog_jwt.dart';
import 'package:postgres/postgres.dart';

import '../models/models.dart';

Handler middleware(Handler handler) {
  final tokenEnv = TokenEnv(
    accessTokenSecret:
        Platform.environment['ACCESS_TOKEN_SECRET'] ?? 'my-access-token-secret',
    accessTokenExpire:
        int.parse(Platform.environment['ACCESS_TOKEN_EXIPRE'] ?? '4'),
    refreshTokenSecret:
        Platform.environment['REFRESH_TOKEN_SECRET'] ?? 'refresh-token-secret',
    refreshTokenExpire:
        int.parse(Platform.environment['REFRESH_TOKEN_EXPIRE'] ?? '7'),
  );

  final dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
  final dbPort = int.parse(Platform.environment['DB_PORT'] ?? '5432');
  final dbName = Platform.environment['DB_NAME'] ?? 'databaseName';
  final dbPassword = Platform.environment['DB_PASSWORD'];
  final dbUser = Platform.environment['DB_USER'];

  final pg = PostgreSQLConnection(
    dbHost,
    dbPort,
    dbName,
    username: dbUser,
    password: dbPassword,
  );

  return handler
      .use(provider<TokenEnv>((context) => tokenEnv))
      .use(provider<PostgreSQLConnection>((context) => pg))
      .use(
        frogJwt(
          secret: tokenEnv.accessTokenSecret,
          unless: [
            const UriPath('api/tokens', methods: [HttpMethod.post])
          ],
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
