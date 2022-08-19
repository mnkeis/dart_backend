import 'package:equatable/equatable.dart';

/// {@template recovery_token}
/// Contains a temporary password recovery token
/// along with a valid username and email
/// {@endtemplate}
class RecoveryToken extends Equatable {
  /// {@macro recovery_token}
  const RecoveryToken({
    required this.email,
    required this.username,
    required this.token,
  });

  /// JWT token to enable temporary access to the protected API
  final String token;

  /// Username corresponding to the user performing the action
  final String username;

  /// Email corresponding to the user performing the action
  final String email;

  @override
  List<Object?> get props => [email, username, token];
}
