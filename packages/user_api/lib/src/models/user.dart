import 'package:equatable/equatable.dart';

part 'user.g.dart';

/// {@template user}
/// User description
/// {@endtemplate}
class User extends Equatable {
  /// {@macro user}
  const User({
    required this.username,
    required this.email,
    required this.name,
    required this.lastName,
  });

  /// Creates a User from Json map
  factory User.fromJson(Map<String, dynamic> data) => _$UserFromJson(data);

  /// A description for username
  final String username;

  /// A description for email
  final String email;

  /// A description for name
  final String name;

  /// A description for lastName
  final String lastName;

  /// Creates a copy of the current User with property changes
  User copyWith({
    String? username,
    String? hashedPassword,
    String? email,
    String? name,
    String? lastName,
  }) {
    return User(
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
    );
  }

  @override
  List<Object?> get props => [
        username,
        email,
        name,
        lastName,
      ];

  /// Creates a Json map from a User
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
