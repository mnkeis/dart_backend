import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class TokenNotFoundError extends JWTError {
  TokenNotFoundError(super.message);
}

class UriPath {
  const UriPath(this.path, {this.methods});
  final String path;
  final List<String>? methods;
}

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
            if (element.methods?.contains(context.request.method.value) ??
                true) {
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
        final jwt = JWT.verify(jwtToken, SecretKey(secret));
        handler.use(provider<JWT>((context) => jwt));
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
