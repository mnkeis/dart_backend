import 'package:equatable/equatable.dart';

part 'user.g.dart';

/// {@template user_not_found_exception}
/// Exception thrown when invalid username of password
/// {@endtemplate}
class UserNotFoundException implements Exception {}

/// Available user roles
enum Roles {
  /// admin role
  admin,

  /// user role
  user,

  /// no privileges
  none;

  /// Get Role from string
  factory Roles.fromString(String role) {
    switch (role) {
      case 'admin':
        return Roles.admin;
      case 'user':
        return Roles.user;
      default:
        return Roles.none;
    }
  }
}

/// {@template user}
/// User description
/// {@endtemplate}
class User extends Equatable {
  /// {@macro user}
  const User({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    this.phone,
    this.photoUrl,
    this.roles = const [],
    this.refreshTokens = const [],
  });

  /// Creates a User from Json map
  factory User.fromJson(Map<String, dynamic> data) => _$UserFromJson(data);

  /// An id that uniquely identifies the user
  final int id;

  /// The username that the user should use to identify himself (must be unique)
  final String username;

  /// The user's email
  final String email;

  /// The user's given name
  final String? name;

  /// The user's phone number
  final String? phone;

  /// The user's photo url
  final String? photoUrl;

  /// The user roles
  final List<Roles> roles;

  /// The list of assigned refresh tokens
  final List<String> refreshTokens;

  /// Creates a copy of the current User with property changes
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    List<Roles>? roles,
    List<String>? refreshTokens,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      roles: roles ?? this.roles,
      refreshTokens: refreshTokens ?? this.refreshTokens,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        name,
        phone,
        photoUrl,
        roles,
        refreshTokens,
      ];

  /// Creates a Json map from a User
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
