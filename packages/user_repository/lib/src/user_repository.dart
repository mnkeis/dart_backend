import 'dart:developer';

import 'package:async/async.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:user_api/user_api.dart';

import 'models/models.dart';

/// {@template user_repository}
/// A Very Good Project created by Very Good CLI.
/// {@endtemplate}
class UserRepository {
  /// {@macro user_repository}
  const UserRepository(
    this._userApi, {
    required String accessTokenSecret,
    required String refreshTokenSecret,
    int? accessTokenExpire,
    int? refreshTokenExpire,
  })  : _accessTokenSecret = accessTokenSecret,
        _refreshTokenSecret = refreshTokenSecret,
        _accessTokenExpire = accessTokenExpire,
        _refreshTokenExpire = refreshTokenExpire;

  final UserApi _userApi;
  final String _accessTokenSecret;
  final String _refreshTokenSecret;
  final int? _accessTokenExpire;
  final int? _refreshTokenExpire;

  /// User trying to login with username and password
  Future<Result<Tokens>> createAccessTokenFromUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    try {
      final user = await _userApi.getUserWithUsernameAndPassword(
        username: username,
        password: password,
      );

      if (user == null) {
        return Result.error(
          const AuthenticationException(
            AuthenticationFailure.invalidUsernameOrPassword,
          ),
        );
      }

      final tokens = _createTokens(user);
      final updatedUser = user.copyWith(
        refreshTokens: [...user.refreshTokens, tokens.refreshToken],
      );
      await _userApi.updateUser(updatedUser);
      return Result.value(tokens);
    } catch (e) {
      // Should never reach here
      log(
        'Invalid user query error',
        name: 'login-with-username-and-password-unexpected-error',
        error: e,
        time: DateTime.now(),
      );
      return Result.error(e);
    }
  }

  /// A user requiring a new access token provides a refresh token
  Future<Result<Tokens>> createAccessTokenFromRefreshToken(
    String refreshToken,
  ) async {
    try {
      final oldJwt = JWT.verify(refreshToken, SecretKey(_refreshTokenSecret));
      final tokenUser = await _userApi.getUserWithRefreshToken(refreshToken);
      if (tokenUser == null) {
        // Someone is doing something nasty!!
        // Detected refresh token reuse
        final json = oldJwt.payload as Map<String, dynamic>;
        final user = await _userApi.getUserById(json['id'] as int);
        // Delete all refresh tokens for the user
        await _userApi.updateUser(user.copyWith(refreshTokens: []));
        return Result.error(
          const TokenException(
            TokenFailure.refreshTokenReused,
          ),
        );
      }
      // Delete the old token from the array
      final newTokenUser = tokenUser.copyWith(
        refreshTokens: tokenUser.refreshTokens
            .where((element) => element != refreshToken)
            .toList(),
      );
      final tokens = _createTokens(newTokenUser);
      await _userApi.updateUser(
        newTokenUser.copyWith(
          refreshTokens: [...newTokenUser.refreshTokens, tokens.refreshToken],
        ),
      );
      return Result.value(tokens);
    } catch (e) {
      if (e is JWTUndefinedError) {
        if (e.error is JWTExpiredError) {
          return Result.error(
            const TokenException(
              TokenFailure.tokenExpired,
            ),
          );
        }
        if (e.error is JWTInvalidError || e.error is JWTParseError) {
          return Result.error(
            const TokenException(
              TokenFailure.tokenInvalid,
            ),
          );
        }
      }
      return Result.error(e);
    }
  }

  /// Delete all refresh tokens of a user
  Future<void> revokeAllRefreshTokens(int id) async {
    final user = await _userApi.getUserById(id);
    await _userApi.updateUser(user.copyWith(refreshTokens: []));
  }

  /// Returns a user object by its id
  Future<Result<User>> getUser(int id) async {
    try {
      final user = await _userApi.getUserById(id);
      return Result.value(user.copyWith(refreshTokens: []));
    } catch (e) {
      return Result.error(e);
    }
  }

  /// Verify if [username] is avaliable
  Future<Result<bool>> verifyUsername(String username) async {
    final available = await _userApi.verifyUsername(username);
    return Result.value(available);
  }

  /// Creates a new user (register)
  Future<Result<User>> addUser({
    required User user,
    required String password,
  }) async {
    final created = await _userApi.createUser(user: user, password: password);
    if (!created) {
      return Result.error(
        const AuthenticationException(
          AuthenticationFailure.usernameNotAvailable,
        ),
      );
    }
    final newUser = await _userApi.getUserWithUsernameAndPassword(
      username: user.username,
      password: password,
    );
    if (newUser == null) {
      return Result.error(
        const AuthenticationException(
          AuthenticationFailure.registrationFailed,
        ),
      );
    }
    return Result.value(newUser);
  }

  /// Update user profile
  Future<Result<void>> updateProfile(User user) async {
    try {
      await _userApi.updateUser(user);
      return Result.value(null);
    } catch (e) {
      return Result.error(e);
    }
  }

  /// Update user password
  Future<Result<void>> updatePassword({
    required String username,
    required String password,
    required String newPassword,
  }) async {
    final user = await _userApi.getUserWithUsernameAndPassword(
      username: username,
      password: password,
    );
    if (user == null) {
      return Result.error(
        const AuthenticationException(
          AuthenticationFailure.invalidUsernameOrPassword,
        ),
      );
    }
    try {
      await _userApi.updateUserPassword(user: user, password: newPassword);
      return Result.value(null);
    } catch (e) {
      return Result.error(e);
    }
  }

  /// Returns a temporary access token that can be used to recover
  /// a user password
  Future<Result<RecoveryToken>> getPasswordRecoveryToken(
    String usernameOrEmail,
  ) async {
    final user = await _userApi.getUserWithUsernameOrEmail(usernameOrEmail);
    if (user == null) {
      return Result.error(
        const AuthenticationException(AuthenticationFailure.userNotFound),
      );
    }
    final tokens = _createTokens(user);

    final token = RecoveryToken(
      email: user.email,
      username: user.username,
      token: tokens.accessToken,
    );

    return Result.value(token);
  }

  /// Recovery password opration
  Future<Result<void>> recoverPassword({
    required int id,
    required String newPassword,
  }) async {
    try {
      final user = await _userApi.getUserById(id);
      await _userApi.updateUserPassword(user: user, password: newPassword);
      return Result.value(null);
    } catch (e) {
      return Result.error(e);
    }
  }

  Tokens _createTokens(User user) {
    final payload = user.toJson()
      ..removeWhere((key, value) => key == 'refreshTokens');
    final jwt = JWT(payload);
    return Tokens(
      accessToken: jwt.sign(
        SecretKey(_accessTokenSecret),
        expiresIn: Duration(hours: _accessTokenExpire ?? 4),
      ),
      refreshToken: jwt.sign(
        SecretKey(_refreshTokenSecret),
        expiresIn: Duration(days: _refreshTokenExpire ?? 7),
      ),
    );
  }
}
