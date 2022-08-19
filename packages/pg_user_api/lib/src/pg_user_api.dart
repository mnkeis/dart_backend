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

  Future<void> _connectDb() async {
    if (_pg.isClosed) {
      await _pg.open();
    }
  }

  @override
  Future<User?> getUserWithUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    await _connectDb();
    final hashedPassword = sha256.convert(utf8.encode(password));
    final dbResult = await _pg.mappedResultsQuery(
      '''
        SELECT * FROM users 
        WHERE username = @username AND hashed_password = @hashedPassword''',
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
    await _connectDb();
    final result = await _pg.mappedResultsQuery(
      '''
      SELECT * FROM users WHERE @refreshToken = ANY(refresh_tokens)''',
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
  Future<User?> getUserWithUsernameOrEmail(String usernameOrEmail) async {
    await _connectDb();
    final result = await _pg.mappedResultsQuery(
      '''
      SELECT * FROM users WHERE 
      username = @usernameOrEmail OR email = @usernameOrEmail
''',
      substitutionValues: {'usernameOrEmail': usernameOrEmail},
    );
    if (result.isEmpty) {
      return null;
    }
    if (result.length > 1) {
      throw PostgreSQLException('invalid-result-set');
    }
    try {
      return User.fromJson(result.first.values.first);
    } catch (_) {
      throw const FormatException();
    }
  }

  @override
  Future<User> getUserById(int id) async {
    await _connectDb();
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
    await _connectDb();
    await _pg.query(
      '''
        UPDATE users SET
          email = @email, name = @name, phone = @phone, 
          photo_url = @photoUrl, roles = @roles, 
          refresh_tokens = @refreshTokens
        WHERE id = @id''',
      substitutionValues: user.toJson(),
    );
  }

  @override
  Future<void> updateUserPassword({
    required User user,
    required String password,
  }) async {
    await _connectDb();
    final dbResult = await _pg.mappedResultsQuery(
      '''
      SELECT * FROM users WHERE username = @username''',
      substitutionValues: {'username': user.username},
    );
    if (dbResult.isEmpty) {
      throw Exception();
    }
    final newUser = User.fromJson(dbResult.first.values.first);
    final hashedPassword = sha256.convert(utf8.encode(password));

    await _pg.mappedResultsQuery(
      '''
      UPDATE user SET hashed_password = @hashedPassword
      WHERE id = @id''',
      substitutionValues: {
        'id': newUser.id,
        'hashedPassword': base64.encode(hashedPassword.bytes),
      },
    );
  }

  @override
  Future<bool> verifyUsername(String username) async {
    if (username.length < 6) {
      return false;
    }
    await _connectDb();
    final dbResult = await _pg.mappedResultsQuery(
      '''
      SELECT * FROM users WHERE username = @username''',
      substitutionValues: {'username': username},
    );
    return dbResult.isEmpty;
  }

  @override
  Future<bool> createUser({
    required User user,
    required String password,
  }) async {
    await _connectDb();
    final dbResult = await _pg.mappedResultsQuery(
      '''
      SELECT * FROM users WHERE username = @username''',
      substitutionValues: {'username': user.username},
    );
    if (dbResult.isNotEmpty) {
      return false;
    }
    final hashedPassword = sha256.convert(utf8.encode(password));
    await _pg.mappedResultsQuery(
      '''
      INSERT INTO users 
      (username, email, name, phone, photo_url, roles, hashed_password)
      VALUES (@username, @email, @name, @phone, @photoUrl, @roles, @hashedPassword)''',
      substitutionValues: {
        ...user.toJson(),
        'hashedPassword': base64.encode(hashedPassword.bytes),
      },
    );
    return true;
  }
}
