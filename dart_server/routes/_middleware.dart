import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:frog_jwt/frog_jwt.dart';

import '../models/models.dart';

Handler middleware(Handler handler) {
  final config = Config(
    accessTokenSecret:
        Platform.environment['ACCESS_TOKEN_SECRET'] ?? 'my-access-token-secret',
    accessTokenExpire:
        int.parse(Platform.environment['ACCESS_TOKEN_EXIPRE'] ?? '4'),
    refreshTokenSecret:
        Platform.environment['REFRESH_TOKEN_SECRET'] ?? 'refresh-token-secret',
    refreshTokenExpire:
        int.parse(Platform.environment['REFRESH_TOKEN_EXPIRE'] ?? '7'),
    dbHost: Platform.environment['DB_HOST'] ?? 'localhost',
    dbPort: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
    dbName: Platform.environment['DB_NAME'] ?? 'postgres',
    dbPassword: Platform.environment['DB_PASSWORD'] ?? 'db_password',
    dbUser: Platform.environment['DB_USER'] ?? 'postgres',
  );

  return handler
      .use(requestLogger())
      .use(provider<Config>((context) => config))
      .use(
        frogJwt(
          secret: config.accessTokenSecret,
          unless: [
            const UriPath(
              'api/users/authenticate',
              methods: [HttpMethod.post],
            ),
            const UriPath(
              'api/users/refresh_token',
              methods: [HttpMethod.post],
            ),
            const UriPath(
              'api/users/register',
              methods: [HttpMethod.post],
            )
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
      )
      .use((handler) {
    return handler;
  });
  //     .use(
  //   provider<User>((context) {
  //     final token = context.request.headers['Authorization']
  //             ?.replaceFirst('Bearer ', '') ??
  //         context.request.url.queryParameters['token'];
  //     final jwt = JWT.verify(token!, SecretKey(tokenEnv.accessTokenSecret));
  //     return User.fromJson(jwt.payload as Map<String, dynamic>);
  //   }),
  // );
}
