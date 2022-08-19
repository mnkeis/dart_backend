import 'package:dart_frog/dart_frog.dart';
import 'package:pg_user_api/pg_user_api.dart';
import 'package:postgres/postgres.dart';
import 'package:user_repository/user_repository.dart';

import '../../../models/models.dart';

Handler middleware(Handler handler) {
  return handler.use(
    provider<UserRepository>((context) {
      final config = context.read<Config>();

      final pg = PostgreSQLConnection(
        config.dbHost,
        config.dbPort,
        config.dbName,
        username: config.dbUser,
        password: config.dbPassword,
      );

      return UserRepository(
        PgUserApi(pg),
        accessTokenSecret: config.accessTokenSecret,
        accessTokenExpire: config.accessTokenExpire,
        refreshTokenSecret: config.refreshTokenSecret,
        refreshTokenExpire: config.refreshTokenExpire,
      );
    }),
  );
}
