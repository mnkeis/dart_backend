import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:frog_jwt/frog_jwt.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  const text = 'hello';
  const secret = 'my-secret';
  final jwt = JWT({'id': 1234});
  final token = jwt.sign(SecretKey(secret));
  final context = _MockRequestContext();
  Response onError(Error error) {
    if (error is TokenNotFoundError) {
      return Response(statusCode: HttpStatus.unauthorized);
    }
    if (error is JWTInvalidError || error is JWTExpiredError) {
      return Response(statusCode: HttpStatus.forbidden);
    }
    throw error;
  }

  group('JWT middleware', () {
    test('allows request with valid token', () async {
      Handler middleware(Handler handler) {
        return handler.use(frogJwt(secret: secret, token: token));
      }

      Response onRequest(RequestContext context) {
        return Response(body: text);
      }

      final handler =
          const Pipeline().addMiddleware(middleware).addHandler(onRequest);
      final request = Request.get(Uri.parse('http://localhost/'));
      when(() => context.request).thenReturn(request);
      final response = await handler(context);
      await expectLater(response.statusCode, equals(HttpStatus.ok));
      await expectLater(await response.body(), equals(text));
    });

    test('allows unauthorized request on "unless" path', () async {
      Handler middleware(Handler handler) {
        return handler.use(
          frogJwt(
            secret: secret,
            unless: [const UriPath('auth')],
          ),
        );
      }

      Response onRequest(RequestContext context) {
        return Response(body: text);
      }

      final handler =
          const Pipeline().addMiddleware(middleware).addHandler(onRequest);
      final request = Request.get(Uri.parse('http://localhost/auth'));
      when(() => context.request).thenReturn(request);
      final response = await handler(context);
      await expectLater(response.statusCode, equals(HttpStatus.ok));
      await expectLater(await response.body(), equals(text));
    });

    test('getToken extracts token from query string', () async {
      Handler middleware(Handler handler) {
        return handler.use(
          frogJwt(
            secret: secret,
            getToken: (request) {
              return request.url.queryParameters['token'];
            },
          ),
        );
      }

      Response onRequest(RequestContext context) {
        return Response(body: text);
      }

      final handler =
          const Pipeline().addMiddleware(middleware).addHandler(onRequest);
      final request = Request.get(
        Uri.parse('http://localhost/hello?token=$token'),
      );
      when(() => context.request).thenReturn(request);
      final response = await handler(context);
      await expectLater(response.statusCode, equals(HttpStatus.ok));
      await expectLater(await response.body(), equals(text));
    });

    test('getToken extracts token from headers', () async {
      Handler middleware(Handler handler) {
        return handler.use(
          frogJwt(
            secret: secret,
            getToken: (request) {
              return request.headers['Authorization']
                  ?.replaceFirst('Bearer ', '');
            },
          ),
        );
      }

      Response onRequest(RequestContext context) {
        return Response(body: text);
      }

      final handler =
          const Pipeline().addMiddleware(middleware).addHandler(onRequest);
      final request = Request.get(
        Uri.parse('http://localhost/hello'),
        headers: {'Authorization': 'Bearer $token'},
      );
      when(() => context.request).thenReturn(request);
      final response = await handler(context);
      await expectLater(response.statusCode, equals(HttpStatus.ok));
      await expectLater(await response.body(), equals(text));
    });

    test('throws TokenNotFoundError when no token', () async {
      Handler middleware(Handler handler) {
        return handler.use(
          frogJwt(
            secret: secret,
          ),
        );
      }

      Response onRequest(RequestContext context) {
        return Response(body: text);
      }

      final handler =
          const Pipeline().addMiddleware(middleware).addHandler(onRequest);
      final request = Request.get(
        Uri.parse('http://localhost/hello'),
      );
      when(() => context.request).thenReturn(request);
      await expectLater(
        handler(context),
        throwsA(isA<TokenNotFoundError>()),
      );
    });

    test('throws JWTInvalidError when token is invalid', () async {
      Handler middleware(Handler handler) {
        return handler.use(
          frogJwt(
            secret: 'another-secret',
            token: token,
          ),
        );
      }

      Response onRequest(RequestContext context) {
        return Response(body: text);
      }

      final handler =
          const Pipeline().addMiddleware(middleware).addHandler(onRequest);
      final request = Request.get(
        Uri.parse('http://localhost/hello'),
      );
      when(() => context.request).thenReturn(request);
      await expectLater(
        handler(context),
        throwsA(
          isA<JWTUndefinedError>()
              .having(
            (p0) => p0.error,
            'invalid error',
            isA<JWTInvalidError>(),
          )
              .having(
            (p0) {
              final error = p0.error as JWTInvalidError;
              return error.message;
            },
            'invalid signature',
            equals('invalid signature'),
          ),
        ),
      );
    });

    test('throws JWTExpiredError when token is expired', () async {
      final token = jwt.sign(SecretKey(secret), expiresIn: Duration.zero);

      Handler middleware(Handler handler) {
        return handler.use(
          frogJwt(
            secret: secret,
            token: token,
          ),
        );
      }

      Response onRequest(RequestContext context) {
        return Response(body: text);
      }

      final handler =
          const Pipeline().addMiddleware(middleware).addHandler(onRequest);
      final request = Request.get(
        Uri.parse('http://localhost/hello'),
      );
      when(() => context.request).thenReturn(request);
      await expectLater(
        handler(context),
        throwsA(
          isA<JWTUndefinedError>()
              .having(
            (p0) => p0.error,
            'jwt expired error',
            isA<JWTExpiredError>(),
          )
              .having(
            (p0) {
              final error = p0.error as JWTExpiredError;
              return error.message;
            },
            'jwt expired',
            equals('jwt expired'),
          ),
        ),
      );
    });

    test('onError callback gets called with TokenNotFoundError', () async {
      Handler middleware(Handler handler) {
        return handler.use(
          frogJwt(
            secret: secret,
            onError: onError,
          ),
        );
      }

      Response onRequest(RequestContext context) {
        return Response(body: text);
      }

      final handler =
          const Pipeline().addMiddleware(middleware).addHandler(onRequest);
      final request = Request.get(
        Uri.parse('http://localhost/hello'),
      );
      when(() => context.request).thenReturn(request);
      final response = await handler(context);
      await expectLater(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('onError callback gets called with JWTUndefinedError', () async {
      Handler middleware(Handler handler) {
        return handler.use(
          frogJwt(
            secret: 'another-secret',
            token: token,
            onError: onError,
          ),
        );
      }

      Response onRequest(RequestContext context) {
        return Response(body: text);
      }

      final handler =
          const Pipeline().addMiddleware(middleware).addHandler(onRequest);
      final request = Request.get(
        Uri.parse('http://localhost/hello'),
      );
      when(() => context.request).thenReturn(request);
      final response = await handler(context);
      await expectLater(response.statusCode, equals(HttpStatus.forbidden));
    });
  });
}
