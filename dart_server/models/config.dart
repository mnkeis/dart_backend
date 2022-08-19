class Config {
  Config({
    required this.accessTokenSecret,
    required this.accessTokenExpire,
    required this.refreshTokenSecret,
    required this.refreshTokenExpire,
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
  });

  final String accessTokenSecret;
  final int accessTokenExpire;
  final String refreshTokenSecret;
  final int refreshTokenExpire;
  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbPassword;
  final String dbUser;
}
