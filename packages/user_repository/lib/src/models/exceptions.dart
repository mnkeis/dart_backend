/// {@template authentication_exception}
/// Exception thrown when an unauthorized operation occurs
/// {@endtemplate}
class AuthenticationException implements Exception {
  /// {@macro authentication_exception}
  const AuthenticationException(this.failure);

  /// Failure reason
  final AuthenticationFailure failure;
}

/// {@template authentication_failure}
/// Authentication expecption reasons
/// {@endtemplate}
enum AuthenticationFailure {
  /// Authentication failed with an invalid username or password
  invalidUsernameOrPassword,

  /// Unauthorized exception thrown by an invalid token
  tokenInvalid,

  /// Unauthorized exception thrown by an expired token
  tokenExpired,

  /// Unauthorized exception thrown by a refresh token reuse detected
  refreshTokenReused,
}
