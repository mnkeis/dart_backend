import 'package:equatable/equatable.dart';

/// {@template tokens}
/// Represents a pair of access and refresh tokens
/// {@endtemplate}
class Tokens extends Equatable {
  /// {@macro tokens}
  const Tokens({
    required this.accessToken,
    required this.refreshToken,
  });

  /// Access token
  final String accessToken;

  /// Refresh token
  final String refreshToken;

  /// Returns the JSON representation for the class
  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
