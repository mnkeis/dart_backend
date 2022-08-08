import 'models/user.dart';

/// {@template user_api}
/// A Very Good Project created by Very Good CLI.
/// {@endtemplate}
abstract class UserApi {
  /// {@macro user_api}
  const UserApi();

  /// User trying to login with username and password
  Future<User> getUserWithUsernameAndPassword({
    required String username,
    required String password,
  });
}
