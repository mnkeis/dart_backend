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

  /// Username is not available
  usernameNotAvailable,

  /// Error ocurred while registering
  registrationFailed,

  /// User not found
  userNotFound,
}
