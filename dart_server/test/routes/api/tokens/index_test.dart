import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

import '../../../../routes/api/tokens/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockUserApi extends Mock implements UserApi {}

void main() {
  const secret = 'my-secret';
  const username = '__test_username__';
  const password = '__test_password__';
  final context = _MockRequestContext();
  final userApi = _MockUserApi();
  final body = <String, dynamic>{
    'username': username,
    'password': password,
  };
  const user = User(
    username: 'test_username',
    email: 'test@email.com',
    name: 'testName',
    lastName: 'testLastName',
  );
  final userRepository = UserRepository(userApi);
  group('Tokens', () {
    test('create a new token', () async {
      final jwt = JWT(user);
      final token = jwt.sign(SecretKey(secret));
      Handler middleware(Handler handler) {
        return handler
            .use(provider<String>((context) => secret))
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
      final response = await handler(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.json(), completion({'token': token}));
    });
  });
}
