// ignore_for_file: prefer_const_constructors
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pg_user_api/pg_user_api.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:user_api/user_api.dart';

class _MockPostgreSQLConnection extends Mock implements PostgreSQLConnection {}

void main() {
  const username = '__test_username__';
  const password = '__test_password__';
  const email = 'user@example.com';
  const givenName = '__test_given_name__';
  const phone = '__test_phone_number';
  final pgConnection = _MockPostgreSQLConnection();
  group('PgUserApi', () {
    test('can be instantiated', () {
      expect(PgUserApi(pgConnection), isNotNull);
    });

    group('method getUserWithUsernameAndPassword', () {
      test('returns a valid user', () async {
        final hashedPassword = sha256.convert(utf8.encode(password));
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'username': username,
              'hashedPassword': base64.encode(hashedPassword.bytes),
            },
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {
                'id': 1,
                'username': username,
                'email': email,
                'name': givenName,
                'phone': phone,
              }
            }
          ],
        );
        final userApi = PgUserApi(pgConnection);
        final user = await userApi.getUserWithUsernameAndPassword(
          username: username,
          password: password,
        );
        expect(
          user,
          User(
            id: 1,
            username: username,
            email: email,
            name: givenName,
            phone: phone,
          ),
        );
      });

      test('returns null when invalid username or password', () async {
        final hashedPassword = sha256.convert(utf8.encode(password));
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'username': username,
              'hashedPassword': base64.encode(hashedPassword.bytes),
            },
          ),
        ).thenAnswer(
          (_) async => [],
        );
        final userApi = PgUserApi(pgConnection);
        final result = userApi.getUserWithUsernameAndPassword(
          username: username,
          password: password,
        );
        await expectLater(result, completion(null));
      });

      test('throws PostgreSQLException if db returns more than one row',
          () async {
        final hashedPassword = sha256.convert(utf8.encode(password));
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'username': username,
              'hashedPassword': base64.encode(hashedPassword.bytes),
            },
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {'username': username}
            },
            {
              'users': {'username': username}
            }
          ],
        );
        final userApi = PgUserApi(pgConnection);
        final result = userApi.getUserWithUsernameAndPassword(
          username: username,
          password: password,
        );
        await expectLater(result, throwsA(isA<PostgreSQLException>()));
      });

      test('throws FormatException if db returns an invalid result', () async {
        final hashedPassword = sha256.convert(utf8.encode(password));
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'username': username,
              'hashedPassword': base64.encode(hashedPassword.bytes),
            },
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {'username': username}
            },
          ],
        );
        final userApi = PgUserApi(pgConnection);
        final result = userApi.getUserWithUsernameAndPassword(
          username: username,
          password: password,
        );
        await expectLater(result, throwsA(isA<FormatException>()));
      });
    });

    group('method getUserWithUsernameOrEmail', () {
      test('returns a valid user', () async {
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: any(named: 'substitutionValues'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {
                'id': 1,
                'username': username,
                'email': email,
                'name': givenName,
                'phone': phone,
              }
            }
          ],
        );
        final userApi = PgUserApi(pgConnection);
        final user =
            await userApi.getUserWithUsernameOrEmail('usernameOrPassword');
        expect(
          user,
          User(
            id: 1,
            username: username,
            email: email,
            name: givenName,
            phone: phone,
          ),
        );
      });

      test('returns null when invalid username or email', () async {
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: any(named: 'substitutionValues'),
          ),
        ).thenAnswer(
          (_) async => [],
        );
        final userApi = PgUserApi(pgConnection);
        final result =
            userApi.getUserWithUsernameOrEmail('inexistentUsernameAndEmail');
        await expectLater(result, completion(null));
      });

      test('throws PostgreSQLException if db returns more than one row',
          () async {
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: any(named: 'substitutionValues'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {'username': username}
            },
            {
              'users': {'username': username}
            }
          ],
        );
        final userApi = PgUserApi(pgConnection);
        final result = userApi.getUserWithUsernameOrEmail('usernameOrEmail');
        await expectLater(result, throwsA(isA<PostgreSQLException>()));
      });

      test('throws FormatException if db returns an invalid result', () async {
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: any(named: 'substitutionValues'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {'username': username}
            },
          ],
        );
        final userApi = PgUserApi(pgConnection);
        final result = userApi.getUserWithUsernameOrEmail('usernameOrEmail');
        await expectLater(result, throwsA(isA<FormatException>()));
      });
    });

    group('method getUserWithRefreshToken', () {
      test('returns a user if the token is valid', () async {
        const refreshToken = 'some-refresh-token';
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'refreshToken': refreshToken,
            },
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {
                'id': 1,
                'username': username,
                'email': email,
                'name': givenName,
                'phone': phone,
              }
            }
          ],
        );
        final userApi = PgUserApi(pgConnection);
        final user = await userApi.getUserWithRefreshToken(refreshToken);
        expect(
          user,
          User(
            id: 1,
            username: username,
            email: email,
            name: givenName,
            phone: phone,
          ),
        );
      });

      test('returns null if the token is not found', () async {
        const refreshToken = 'some-refresh-token';
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'refreshToken': refreshToken,
            },
          ),
        ).thenAnswer(
          (_) async => [],
        );
        final userApi = PgUserApi(pgConnection);
        final user = await userApi.getUserWithRefreshToken(refreshToken);
        expect(
          user,
          isNull,
        );
      });
    });

    group('method getUserById', () {
      test('returns a user if id is valid', () async {
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'id': 1,
            },
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {
                'id': 1,
                'username': username,
                'email': email,
                'name': givenName,
                'phone': phone,
              }
            }
          ],
        );
        final userApi = PgUserApi(pgConnection);
        final user = await userApi.getUserById(1);
        expect(
          user,
          User(
            id: 1,
            username: username,
            email: email,
            name: givenName,
            phone: phone,
          ),
        );
      });

      test('throws ProgreSQLException if id is not valid', () async {
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'id': 1,
            },
          ),
        ).thenAnswer(
          (_) async => [],
        );
        final userApi = PgUserApi(pgConnection);
        expect(
          userApi.getUserById(1),
          throwsA(isA<PostgreSQLException>()),
        );
      });
    });
    group('method updateUserPassword', () {
      test('executes sucessfully when user exists', () async {
        const newPassword = 'new-password';
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'username': username,
            },
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {
                'id': 1,
                'username': username,
                'email': email,
                'name': givenName,
                'phone': phone,
              }
            }
          ],
        );
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'id': 1,
              'hashedPassword': sha256.convert(utf8.encode(newPassword))
            },
          ),
        ).thenAnswer(
          (_) async => [],
        );
        final userApi = PgUserApi(pgConnection);
        final user = User(
          id: 1,
          username: username,
          email: email,
          name: givenName,
          phone: phone,
        );
        await userApi.updateUserPassword(user: user, password: newPassword);
        verify(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'id': 1,
              'hashedPassword': sha256.convert(utf8.encode(newPassword))
            },
          ),
        ).called(1);
      });
      test('throws exception if user not exists', () async {
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: {
              'username': username,
            },
          ),
        ).thenAnswer(
          (_) async => [],
        );
        final userApi = PgUserApi(pgConnection);
        final user = User(
          id: 1,
          username: username,
          email: email,
          name: givenName,
          phone: phone,
        );
        final result = userApi.updateUserPassword(user: user, password: 'new');
        await expectLater(result, throwsA(isA<Exception>()));
      });
    });

    group('method verifyUsername', () {
      test('returns false if less than 6 chars', () async {
        final userApi = PgUserApi(pgConnection);
        await expectLater(
          userApi.verifyUsername('user'),
          completion(equals(false)),
        );
      });
      test('returns false is exists', () async {
        final userApi = PgUserApi(pgConnection);
        when(pgConnection.open).thenAnswer((_) async {});
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: any(named: 'substitutionValues'),
          ),
        ).thenAnswer(
          (_) async => [
            {'users': {}}
          ],
        );
        await expectLater(
          userApi.verifyUsername('username'),
          completion(equals(false)),
        );
      });
      test('returns true is not exists', () async {
        final userApi = PgUserApi(pgConnection);
        when(pgConnection.open).thenAnswer((_) async {});
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: any(named: 'substitutionValues'),
          ),
        ).thenAnswer(
          (_) async => [],
        );
        await expectLater(
          userApi.verifyUsername('username'),
          completion(equals(true)),
        );
      });
    });

    group('method createUser', () {
      test('returns true and inserts new user if not exists', () async {
        const newPassword = 'new-password';
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: any(named: 'substitutionValues'),
          ),
        ).thenAnswer(
          (_) async => [],
        );
        final userApi = PgUserApi(pgConnection);
        final user = User(
          id: 1,
          username: username,
          email: email,
          name: givenName,
          phone: phone,
        );
        final result =
            await userApi.createUser(user: user, password: newPassword);
        expect(result, equals(true));
      });
      test('returns false if username exists', () async {
        when(pgConnection.open).thenAnswer((_) async => null);
        when(
          () => pgConnection.mappedResultsQuery(
            any(),
            substitutionValues: any(named: 'substitutionValues'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'users': {
                'id': 1,
                'username': username,
              }
            }
          ],
        );
        final userApi = PgUserApi(pgConnection);
        final user = User(
          id: 1,
          username: username,
          email: email,
          name: givenName,
          phone: phone,
        );
        final result = await userApi.createUser(user: user, password: 'new');
        expect(result, equals(false));
      });
    });
  });
}
