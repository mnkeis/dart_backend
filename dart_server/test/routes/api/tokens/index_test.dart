import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

import '../../../../models/models.dart';
import '../../../../routes/api/tokens/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockUserApi extends Mock implements UserApi {}

void main() {
  const accessTokenSecret = 'my-access-token-secret';
  const refreshTokenSecret = 'my-refresh-token-secret';
  const username = '__test_username__';
  const password = '__test_password__';
  final context = _MockRequestContext();
  final userApi = _MockUserApi();
  final body = <String, dynamic>{
    'username': username,
    'password': password,
  };
  const user = User(
    id: 1,
    username: 'test_username',
    email: 'test@email.com',
    name: 'testName',
    phone: 'testPhoneNumber',
  );
  final userRepository = UserRepository(
    userApi,
    accessTokenSecret: accessTokenSecret,
    refreshTokenSecret: refreshTokenSecret,
  );

  group('Tokens', () {
    group('post method', () {
      test('creates new tokens', () async {
        final payload = user.toJson()
          ..removeWhere((key, value) => key == 'refreshTokens');

        final jwt = JWT(payload);
        final tokens = Tokens(
          accessToken: jwt.sign(
            SecretKey(accessTokenSecret),
            expiresIn: const Duration(hours: 4),
          ),
          refreshToken: jwt.sign(
            SecretKey(refreshTokenSecret),
            expiresIn: const Duration(days: 7),
          ),
        );

        Handler middleware(Handler handler) {
          return handler
              .use(
                provider<TokenEnv>(
                  (context) => TokenEnv(
                    accessTokenSecret: accessTokenSecret,
                    refreshTokenSecret: refreshTokenSecret,
                    accessTokenExpire: 4,
                    refreshTokenExpire: 7,
                  ),
                ),
              )
              .use(provider<UserRepository>((context) => userRepository));
        }

        final handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(route.onRequest);

        final request = Request.post(
          Uri.parse('http://localhost/api/tokens'),
          body: jsonEncode(body),
        );
        when(() => context.request).thenReturn(request);
        when(
          () => userApi.getUserWithUsernameAndPassword(
            username: username,
            password: password,
          ),
        ).thenAnswer((_) async => user);
        final updatedUser = user.copyWith(
          refreshTokens: [...user.refreshTokens, tokens.refreshToken],
        );
        when(() => userApi.updateUser(updatedUser)).thenAnswer((_) async {});
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.ok));
        expect(
          response.json(),
          completion(tokens.toJson()),
        );
      });
      test('returns 401 when invalid username or password', () async {
        Handler middleware(Handler handler) {
          return handler
              .use(
                provider<TokenEnv>(
                  (context) => TokenEnv(
                    accessTokenSecret: accessTokenSecret,
                    refreshTokenSecret: refreshTokenSecret,
                    accessTokenExpire: 4,
                    refreshTokenExpire: 7,
                  ),
                ),
              )
              .use(provider<UserRepository>((context) => userRepository));
        }

        final handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(route.onRequest);

        final request = Request.post(
          Uri.parse('http://localhost/api/tokens'),
          body: jsonEncode(body),
        );
        when(() => context.request).thenReturn(request);
        when(
          () => userApi.getUserWithUsernameAndPassword(
            username: username,
            password: password,
          ),
        ).thenAnswer((_) async => null);
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.unauthorized));
        await expectLater(
          response.body(),
          completion('invalid-username-or-password'),
        );
      });

      test('returns 404 when invalid parameters', () async {
        Handler middleware(Handler handler) {
          return handler
              .use(
                provider<TokenEnv>(
                  (context) => TokenEnv(
                    accessTokenSecret: accessTokenSecret,
                    refreshTokenSecret: refreshTokenSecret,
                    accessTokenExpire: 4,
                    refreshTokenExpire: 7,
                  ),
                ),
              )
              .use(provider<UserRepository>((context) => userRepository));
        }

        final handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(route.onRequest);

        final request = Request.post(
          Uri.parse('http://localhost/api/tokens'),
          body: jsonEncode(<String, dynamic>{}),
        );
        when(() => context.request).thenReturn(request);
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.badRequest));
      });
      test('returns 404 when invalid body', () async {
        Handler middleware(Handler handler) {
          return handler
              .use(
                provider<TokenEnv>(
                  (context) => TokenEnv(
                    accessTokenSecret: accessTokenSecret,
                    refreshTokenSecret: refreshTokenSecret,
                    accessTokenExpire: 4,
                    refreshTokenExpire: 7,
                  ),
                ),
              )
              .use(provider<UserRepository>((context) => userRepository));
        }

        final handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(route.onRequest);

        final request = Request.post(
          Uri.parse('http://localhost/api/tokens'),
          body: '',
        );
        when(() => context.request).thenReturn(request);
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.badRequest));
      });
    });

    group('put method', () {
      test('update tokens', () async {
        final payload = user.toJson()
          ..removeWhere((key, value) => key == 'refreshTokens');
        final jwt = JWT(payload);
        final oldRefreshToken = jwt.sign(
          SecretKey(refreshTokenSecret),
          expiresIn: const Duration(days: 3),
        );
        final tokens = Tokens(
          accessToken: jwt.sign(
            SecretKey(accessTokenSecret),
            expiresIn: const Duration(hours: 4),
          ),
          refreshToken: jwt.sign(
            SecretKey(refreshTokenSecret),
            expiresIn: const Duration(days: 7),
          ),
        );

        Handler middleware(Handler handler) {
          return handler
              .use(
                provider<TokenEnv>(
                  (context) => TokenEnv(
                    accessTokenSecret: accessTokenSecret,
                    refreshTokenSecret: refreshTokenSecret,
                    accessTokenExpire: 4,
                    refreshTokenExpire: 7,
                  ),
                ),
              )
              .use(provider<UserRepository>((context) => userRepository));
        }

        final handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(route.onRequest);

        final request = Request.put(
          Uri.parse('http://localhost/api/tokens'),
          body: jsonEncode(<String, dynamic>{
            'refreshToken': oldRefreshToken,
          }),
        );
        when(() => context.request).thenReturn(request);
        when(
          () => userApi.getUserWithRefreshToken(oldRefreshToken),
        ).thenAnswer((_) async => user);
        final updatedUser = user.copyWith(
          refreshTokens: [...user.refreshTokens, tokens.refreshToken],
        );
        when(() => userApi.updateUser(updatedUser)).thenAnswer((_) async {});
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.ok));
        expect(
          response.json(),
          completion(tokens.toJson()),
        );
      });
      test('returns 401 when expired refresh token', () async {
        final payload = user.toJson()
          ..removeWhere((key, value) => key == 'refreshTokens');
        final jwt = JWT(payload);
        final oldRefreshToken = jwt.sign(
          SecretKey(refreshTokenSecret),
          expiresIn: Duration.zero,
        );

        Handler middleware(Handler handler) {
          return handler
              .use(
                provider<TokenEnv>(
                  (context) => TokenEnv(
                    accessTokenSecret: accessTokenSecret,
                    refreshTokenSecret: refreshTokenSecret,
                    accessTokenExpire: 4,
                    refreshTokenExpire: 7,
                  ),
                ),
              )
              .use(provider<UserRepository>((context) => userRepository));
        }

        final handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(route.onRequest);

        final request = Request.put(
          Uri.parse('http://localhost/api/tokens'),
          body: jsonEncode(<String, dynamic>{
            'refreshToken': oldRefreshToken,
          }),
        );
        when(() => context.request).thenReturn(request);
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.unauthorized));
        await expectLater(response.body(), completion('refresh-token-expired'));
      });

      test('returns 401 when detects refresh token reuse', () async {
        final payload = user.toJson()
          ..removeWhere((key, value) => key == 'refreshTokens');
        final jwt = JWT(payload);
        final oldRefreshToken = jwt.sign(
          SecretKey(refreshTokenSecret),
          expiresIn: const Duration(days: 2),
        );

        Handler middleware(Handler handler) {
          return handler
              .use(
                provider<TokenEnv>(
                  (context) => TokenEnv(
                    accessTokenSecret: accessTokenSecret,
                    refreshTokenSecret: refreshTokenSecret,
                    accessTokenExpire: 4,
                    refreshTokenExpire: 7,
                  ),
                ),
              )
              .use(provider<UserRepository>((context) => userRepository));
        }

        final handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(route.onRequest);

        final request = Request.put(
          Uri.parse('http://localhost/api/tokens'),
          body: jsonEncode(<String, dynamic>{
            'refreshToken': oldRefreshToken,
          }),
        );
        when(() => context.request).thenReturn(request);
        when(() => userApi.getUserWithRefreshToken(oldRefreshToken))
            .thenAnswer((_) async => null);
        when(() => userApi.getUserById(1)).thenAnswer((_) async => user);
        when(() => userApi.updateUser(user.copyWith(refreshTokens: [])))
            .thenAnswer((_) async {});
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.unauthorized));
        await expectLater(response.body(), completion('refresh-token-invalid'));
      });

      test('returns 404 when invalid parameters', () async {
        Handler middleware(Handler handler) {
          return handler
              .use(
                provider<TokenEnv>(
                  (context) => TokenEnv(
                    accessTokenSecret: accessTokenSecret,
                    refreshTokenSecret: refreshTokenSecret,
                    accessTokenExpire: 4,
                    refreshTokenExpire: 7,
                  ),
                ),
              )
              .use(provider<UserRepository>((context) => userRepository));
        }

        final handler = const Pipeline()
            .addMiddleware(middleware)
            .addHandler(route.onRequest);

        final request = Request.put(
          Uri.parse('http://localhost/api/tokens'),
          body: jsonEncode(<String, dynamic>{}),
        );
        when(() => context.request).thenReturn(request);
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.badRequest));
      });
    });
  });
}
