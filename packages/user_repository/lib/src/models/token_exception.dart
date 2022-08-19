/// {@template token_exception}
/// Exception thrown when an unauthorized operation occurs
/// {@endtemplate}
class TokenException implements Exception {
  /// {@macro token_exception}
  const TokenException(this.failure);

  /// Failure reason
  final TokenFailure failure;
}

/// {@template authentication_failure}
/// Authentication expecption reasons
/// {@endtemplate}
enum TokenFailure {
  /// Unauthorized exception thrown by an invalid token
  tokenInvalid,

  /// Unauthorized exception thrown by an expired token
  tokenExpired,

  /// Unauthorized exception thrown by a refresh token reuse detected
  refreshTokenReused,
}
