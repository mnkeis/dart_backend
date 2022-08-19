import 'models/user.dart';

/// {@template user_api}
/// A Very Good Project created by Very Good CLI.
/// {@endtemplate}
abstract class UserApi {
  /// {@macro user_api}
  const UserApi();

  /// User trying to login with username and password
  Future<User?> getUserWithUsernameAndPassword({
    required String username,
    required String password,
  });

  /// Search the user owner of a given refresh token
  Future<User?> getUserWithRefreshToken(String refreshToken);

  /// Search the user with his username or email
  Future<User?> getUserWithUsernameOrEmail(String usernameOrEmail);

  /// Get a user by it's id
  Future<User> getUserById(int id);

  /// Update user
  Future<void> updateUser(User user);

  /// Update user password
  Future<void> updateUserPassword({
    required User user,
    required String password,
  });

  /// Verify username
  Future<bool> verifyUsername(String username);

  /// Inserts a new user
  Future<bool> createUser({
    required User user,
    required String password,
  });
}
