import 'package:user_api/user_api.dart';

/// {@template user_repository}
/// A Very Good Project created by Very Good CLI.
/// {@endtemplate}
class UserRepository {
  /// {@macro user_repository}
  const UserRepository(this._userApi);

  final UserApi _userApi;

  /// User trying to login with username and password
  Future<User> getUserWithUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    return _userApi.getUserWithUsernameAndPassword(
      username: username,
      password: password,
    );
  }
}
