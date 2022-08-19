import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:user_repository/user_repository.dart';

import '../../../../routes/_middleware.dart' as jwt_middleware;
import '../../../../routes/api/users/[id].dart' as route;

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
  late String accessToken;

  setUp(() {
    userApi = _MockUserApi();
    context = _MockRequestContext();

    final payload = user.toJson()
      ..removeWhere((key, value) => key == 'refreshTokens');
    final jwt = JWT(payload);

    accessToken = jwt.sign(
      SecretKey(accessTokenSecret),
      expiresIn: const Duration(hours: 4),
    );

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
        .addHandler((context) => route.onRequest(context, '1'));
  });

  group('users/[id]', () {
    group('get method', () {
      test('returns a user', () async {
        final request = Request.get(
          Uri.parse('http://localhost/api/users/1'),
          headers: <String, Object>{
            'Authorization': 'Bearer $accessToken',
          },
        );
        when(() => context.request).thenReturn(request);
        when(() => userApi.getUserById(1)).thenAnswer((_) async => user);
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.ok));
        await expectLater(
          response.body(),
          completion(equals(jsonEncode(user))),
        );
      });
    });

    group('post method', () {});

    group('put method', () {
      test('updates user profile', () async {
        final jsonBody = <String, dynamic>{
          'id': 1,
          'username': 'username',
          'email': 'test@email.com',
          'name': 'otherName',
          'phone': 'testPhoneNumber',
        };
        final request = Request.put(
          Uri.parse('http://localhost/api/users/1'),
          headers: <String, Object>{
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(jsonBody),
        );
        final updatedUser = User.fromJson(jsonBody);
        when(() => context.request).thenReturn(request);
        when(() => userApi.updateUser(updatedUser)).thenAnswer((_) async {});
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.ok));
      });

      test('updates user password', () async {
        final jsonBody = <String, dynamic>{
          'username': 'username',
          'password': 'old_password',
          'newPassword': 'new_password',
        };
        final request = Request.put(
          Uri.parse('http://localhost/api/users/1'),
          headers: <String, Object>{
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(jsonBody),
        );
        when(() => context.request).thenReturn(request);
        when(
          () => userApi.getUserWithUsernameAndPassword(
            username: 'username',
            password: 'old_password',
          ),
        ).thenAnswer(
          (_) async => user,
        );
        when(
          () => userApi.updateUserPassword(
            user: user,
            password: 'new_password',
          ),
        ).thenAnswer((_) async {});
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.ok));
      });
    });

    group('delete method', () {
      test('returns 200 OK', () async {
        final request = Request.delete(
          Uri.parse('http://localhost/api/users/1'),
          headers: <String, Object>{
            'Authorization': 'Bearer $accessToken',
          },
        );
        when(() => context.request).thenReturn(request);
        when(() => userApi.getUserById(user.id)).thenAnswer((_) async => user);
        when(() => userApi.updateUser(user)).thenAnswer((_) async {});
        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.ok));
      });
    });
  });
}
