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

      test('throws UserNotFoundException when invalid username or password',
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
  });
}
