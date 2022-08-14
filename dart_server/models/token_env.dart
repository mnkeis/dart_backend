class TokenEnv {
  TokenEnv({
    required this.accessTokenSecret,
    required this.accessTokenExpire,
    required this.refreshTokenSecret,
    required this.refreshTokenExpire,
  });

  final String accessTokenSecret;
  final int accessTokenExpire;
  final String refreshTokenSecret;
  final int refreshTokenExpire;
}
