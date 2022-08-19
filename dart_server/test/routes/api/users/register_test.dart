import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

import '../../../../routes/_middleware.dart' as jwt_middleware;
import '../../../../routes/api/users/register.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockUserApi extends Mock implements UserApi {}

void main() {
  const accessTokenSecret = 'my-access-token-secret';
  const refreshTokenSecret = 'my-refresh-token-secret';
  const username = '__test_username__';
  const password = '__test_password__';
  final body = <String, dynamic>{
    'username': username,
    'email': 'test@email.com',
    'name': 'testName',
    'phone': 'testPhoneNumber',
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
      Uri.parse('http://localhost/api/users/register'),
      body: jsonEncode(body),
    );

    handler = const Pipeline()
        .addMiddleware(jwt_middleware.middleware)
        .addMiddleware(middleware)
        .addHandler(route.onRequest);
    when(() => context.request).thenReturn(request);
  });

  group('User register', () {
    test('succeed', () async {
      when(
        () => userApi.getUserWithUsernameAndPassword(
          username: username,
          password: password,
        ),
      ).thenAnswer((_) async => user);
      final newUser = User.fromJson({...body, 'id': -1});
      when(() => userApi.createUser(user: newUser, password: password))
          .thenAnswer((_) async => true);
      final response = await handler(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.json(),
        completion(user.toJson()),
      );
    });

    // test('returns 404 when invalid parameters', () async {
    //   final request = Request.post(
    //     Uri.parse('http://localhost/api/users/authenticate'),
    //     body: jsonEncode(<String, dynamic>{}),
    //   );
    //   when(() => context.request).thenReturn(request);
    //   final response = await handler(context);
    //   expect(response.statusCode, equals(HttpStatus.badRequest));
    // });
    // test('returns 404 when invalid body', () async {
    //   final request = Request.post(
    //     Uri.parse('http://localhost/api/users/authenticate'),
    //     body: '',
    //   );
    //   when(() => context.request).thenReturn(request);
    //   final response = await handler(context);
    //   expect(response.statusCode, equals(HttpStatus.badRequest));
    // });
  });
}
