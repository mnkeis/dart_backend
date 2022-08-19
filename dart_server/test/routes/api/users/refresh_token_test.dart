import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

import '../../../../routes/_middleware.dart' as jwt_middleware;
import '../../../../routes/api/users/refresh_token.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockUserApi extends Mock implements UserApi {}

void main() {
  const accessTokenSecret = 'my-access-token-secret';
  const refreshTokenSecret = 'my-refresh-token-secret';
  const user = User(
    id: 1,
    username: 'test_username',
    email: 'test@email.com',
    name: 'testName',
    phone: 'testPhoneNumber',
  );

  late _MockRequestContext context;
  late _MockUserApi userApi;
  late Handler handler;
  late UserRepository userRepository;

  setUp(() {
    userApi = _MockUserApi();
    context = _MockRequestContext();

    userRepository = UserRepository(
      userApi,
      accessTokenSecret: accessTokenSecret,
      refreshTokenSecret: refreshTokenSecret,
    );
    Handler middleware(Handler handler) {
      return handler.use(provider<UserRepository>((context) => userRepository));
    }

    handler = const Pipeline()
        .addMiddleware(jwt_middleware.middleware)
        .addMiddleware(middleware)
        .addHandler(route.onRequest);
  });

  group('users refresh_token', () {
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

      final request = Request.post(
        Uri.parse('http://localhost/api/users/refresh_token'),
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

      final request = Request.post(
        Uri.parse('http://localhost/api/users/refresh_token'),
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

      final request = Request.post(
        Uri.parse('http://localhost/api/users/refresh_token'),
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
      final request = Request.post(
        Uri.parse('http://localhost/api/users/refresh_token'),
        body: jsonEncode(<String, dynamic>{}),
      );
      when(() => context.request).thenReturn(request);
      final response = await handler(context);
      expect(response.statusCode, equals(HttpStatus.badRequest));
    });
  });
}
