import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// {@template token_not_found_error}
/// Error thrown when no token found
/// {@endtemplate}
class TokenNotFoundError extends JWTError {
  /// {@macro token_not_found_error}
  TokenNotFoundError(super.message);
}

/// {@template uri_path}
/// class to match path and methods
/// {@endtemplate}
class UriPath {
  /// {@macro uri_path}
  const UriPath(this.path, {this.methods});

  /// Path to match
  final String path;

  /// Methods to match
  final List<HttpMethod>? methods;
}

/// {@template frog_jwt}
/// dart_frog middleware to find valid authentication tokens on requests
/// {@endtemplate}
Middleware frogJwt({
  required String secret,
  List<UriPath>? unless,
  String? token,
  String? Function(Request request)? getToken,
  Response Function(Error error)? onError,
}) {
  return (handler) {
    return (context) {
      if (unless?.any((element) {
            if (element.path != context.request.url.path) {
              return false;
            }
            if (element.methods?.contains(context.request.method) ?? true) {
              return true;
            }
            return false;
          }) ??
          false) {
        return handler(context);
      }
      String? jwtToken;
      if (getToken != null) {
        jwtToken = getToken(context.request);
      } else {
        jwtToken = token;
      }
      if (jwtToken == null) {
        if (onError != null) {
          return onError(
            TokenNotFoundError('token-not-found'),
          );
        }
        throw TokenNotFoundError('token-not-found');
      }
      try {
        JWT.verify(jwtToken, SecretKey(secret));
        return handler(context);
      } catch (e) {
        if (e is JWTUndefinedError && onError != null) {
          return onError(e.error);
        }
        rethrow;
      }
    };
  };
}
