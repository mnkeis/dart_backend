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
          const AuthenticationException(
            AuthenticationFailure.refreshTokenReused,
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
            const AuthenticationException(
              AuthenticationFailure.tokenExpired,
            ),
          );
        }
        if (e.error is JWTInvalidError || e.error is JWTParseError) {
          return Result.error(
            const AuthenticationException(
              AuthenticationFailure.tokenInvalid,
            ),
          );
        }
      }
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
