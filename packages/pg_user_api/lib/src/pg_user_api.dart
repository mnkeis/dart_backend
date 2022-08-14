import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:user_api/user_api.dart';

/// {@template pg_user_api}
/// A Very Good Project created by Very Good CLI.
/// {@endtemplate}
class PgUserApi implements UserApi {
  /// {@macro pg_user_api}
  const PgUserApi(this._pg);

  final PostgreSQLConnection _pg;

  @override
  Future<User?> getUserWithUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    await _pg.open();
    final hashedPassword = sha256.convert(utf8.encode(password));
    final dbResult = await _pg.mappedResultsQuery(
      '''
        SELECT * FROM users 
        WHERE username = @username AND hasedPassword = @hashedPassword''',
      substitutionValues: {
        'username': username,
        'hashedPassword': base64.encode(hashedPassword.bytes),
      },
    );
    if (dbResult.isEmpty) {
      return null;
    }

    if (dbResult.length > 1) {
      throw PostgreSQLException('invalid-result-set');
    }
    final row = dbResult.first.values.first;

    try {
      return User.fromJson(row);
    } catch (_) {
      throw const FormatException();
    }
  }

  @override
  Future<User?> getUserWithRefreshToken(String refreshToken) async {
    await _pg.open();
    final result = await _pg.mappedResultsQuery(
      '''
      SELECT * FROM users WHERE @refreshToken = ANY(refresh_token)''',
      substitutionValues: {
        'refreshToken': refreshToken,
      },
    );

    if (result.isEmpty) {
      return null;
    }

    return User.fromJson(result.first.values.first);
  }

  @override
  Future<User> getUserById(int id) async {
    await _pg.open();
    final result = await _pg.mappedResultsQuery(
      '''
      SELECT * FROM users WHERE id = @id''',
      substitutionValues: {'id': id},
    );

    if (result.isEmpty) {
      throw PostgreSQLException('invalid-index');
    }

    return User.fromJson(result.first.values.first);
  }

  @override
  Future<void> updateUser(User user) async {
    await _pg.open();
    await _pg.query(
      '''
        UPDATE users SET 
          (
            email = @email, name = @name, phone = @phone, 
            photo_url = @photoUrl, roles = @roles, 
            refresh_tokens = @refreshTokens
          )''',
      substitutionValues: user.toJson(),
    );
  }
}
