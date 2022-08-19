import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

import '../../../../routes/_middleware.dart' as jwt_middleware;
import '../../../../routes/api/users/authenticate.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockUserApi extends Mock implements UserApi {}

void main() {
  const accessTokenSecret = 'my-access-token-secret';
  const refreshTokenSecret = 'my-refresh-token-secret';
  const username = '__test_username__';
  const password = '__test_password__';
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

    final request = Request.post(
      Uri.parse('http://localhost/api/users/authenticate'),
      body: jsonEncode(body),
    );

    handler = const Pipeline()
        .addMiddleware(jwt_middleware.middleware)
        .addMiddleware(middleware)
        .addHandler(route.onRequest);
    when(() => context.request).thenReturn(request);
  });

  group('User authenticate', () {
    test('with username and password', () async {
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
      final request = Request.post(
        Uri.parse('http://localhost/api/users/authenticate'),
        body: jsonEncode(<String, dynamic>{}),
      );
      when(() => context.request).thenReturn(request);
      final response = await handler(context);
      expect(response.statusCode, equals(HttpStatus.badRequest));
    });
    test('returns 404 when invalid body', () async {
      final request = Request.post(
        Uri.parse('http://localhost/api/users/authenticate'),
        body: '',
      );
      when(() => context.request).thenReturn(request);
      final response = await handler(context);
      expect(response.statusCode, equals(HttpStatus.badRequest));
    });
  });
}
